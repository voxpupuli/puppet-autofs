# Autofs Puppet Module

[![Build Status](https://github.com/voxpupuli/puppet-autofs/workflows/CI/badge.svg)](https://github.com/voxpupuli/puppet-autofs/actions?query=workflow%3ACI)
[![Release](https://github.com/voxpupuli/puppet-autofs/actions/workflows/release.yml/badge.svg)](https://github.com/voxpupuli/puppet-autofs/actions/workflows/release.yml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppet/autofs.svg)](https://forge.puppet.com/puppet/autofs)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/puppet/autofs.svg)](https://forge.puppet.com/puppet/autofs)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/autofs.svg)](https://forge.puppet.com/puppet/autofs)
[![Puppet Forge - scores](https://img.shields.io/puppetforge/f/puppet/autofs.svg)](https://forge.puppet.com/puppet/autofs)
[![puppetmodule.info docs](http://www.puppetmodule.info/images/badge.png)](http://www.puppetmodule.info/m/puppet-autofs)
[![Apache-2 License](https://img.shields.io/github/license/voxpupuli/puppet-autofs.svg)](LICENSE)

---

## Table of Contents

- [Overview](#overview)
- [What this module manages](#what-this-module-manages)
- [Getting started](#getting-started)
- [Concepts: how autofs works](#concepts-how-autofs-works)
- [Common misconceptions and pitfalls](#common-misconceptions-and-pitfalls)
- [The `autofs` class: tuning what is managed](#the-autofs-class-tuning-what-is-managed)
- [The defined types](#the-defined-types)
- [Migrating an existing `/etc/auto.master`](#migrating-an-existing-etcautomaster)
- [Advanced configuration](#advanced-configuration)
- [Limitations and deprecations](#limitations-and-deprecations)
- [Development](#development)
- [Support and authors](#support-and-authors)

---

## Overview

This module installs and manages [autofs](https://en.wikipedia.org/wiki/Autofs),
the daemon that mounts local and remote filesystems **on demand** and
unmounts them after a period of inactivity.

Instead of listing every remote share in `/etc/fstab`, autofs mounts things
only when a client actually reaches for them, which keeps idle network
filesystems off the local system.

The module lets you describe autofs configuration - the package, the service,
the master map, and every map file - through ordinary Puppet manifests and/or
external Hiera data, and it keeps the running `automount` daemon in sync
whenever that content changes.

---

## What this module manages

Depending on how you configure it, the module can manage four things:

| Element | Default location | Puppet representation | Managed by default? |
| --- | --- | --- | --- |
| The autofs package | e.g. `autofs` | `autofs` class (private `autofs::package`) | Yes |
| The autofs service | per-OS via `data/*.yaml` (e.g. `automountd` on AIX) | `autofs` class (private `autofs::service`) | Yes |
| The master map (the index) | `/etc/auto.master` | `autofs::mount`, `autofs::add_master_entry` | Conditionally (see below) |
| The map files (the mounts) | e.g. `/etc/auto.home` | `autofs::mapfile`, `autofs::mapping` | Only when you declare them |

**"Managed by default"** for the master map has an important qualifier: by
default (`manage_auto_master => true`) the module manages `/etc/auto.master` in
full, on an all-or-nothing basis. It writes a managed banner to the file, and
any lines you do not declare are removed on the next run — so a hand-edited
master map **is overwritten**. If you want the module to leave `/etc/auto.master`
untouched, set `manage_auto_master => false` and let another tool own it. See
[Owning versus not owning the master map](#owning-versus-not-owning-the-master-map).

> The master map and the map files are two *different* files that autofs reads
> together. This split is the single most important concept in this module, and
> the source of most confusion. It is explained in detail in
> [Concepts: how autofs works](#concepts-how-autofs-works).

---

## Getting started

The smallest useful configuration installs, enables, and starts autofs with its
default settings:

```puppet
include autofs
```

That installs the service, replaces `auto.master`, gets it running.

To actually get a mount you need **two** resources:

* one that declares the *automount point* in the master map
* one that declares the *map file* content

Here is a complete, self-contained example that mounts a network
share for every user under `/home`:

```puppet
class { 'autofs': }

# 1. Declare the automount point in /etc/auto.master.
autofs::mount { 'home':
  mount   => '/home',
  mapfile => '/etc/auto.home',
}

# 2. Declare the contents of the referenced map file.
autofs::mapping { 'home_default':
  mapfile => '/etc/auto.home',
  key     => '*',
  options => 'rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3',
  fs      => 'server.example.com:/exports/home',
}
```

After the next Puppet run:

```sh
# /etc/auto.master
/home /etc/auto.home

# /etc/auto.home
* -rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3 server.example.com:/exports/home
```

Now, whenever a user accesses `~/.something` that resolves through the network,
autofs mounts `server.example.com:/exports/home` at `/home/<user>` on first
touch and unmounts it after the idle timeout.

### The equivalent in Hiera

You do not have to touch a manifest at all. The same result is obtained by
setting the `mounts` and `mapfiles` class parameters through Hiera. The `mounts`
and `mapfiles` parameters are hashes, so merge them with `merge: hash`:

```yaml
# conf/hiera/common.yaml
lookup_options:
  autofs::mounts:
    merge: hash
  autofs::mapfiles:
    merge: hash

autofs::mounts:
  home:
    mount: '/home'
    mapfile: '/etc/auto.home'

autofs::mapfiles:
  '/etc/auto.home':
    mappings:
      - key: '*'
        options: 'rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3'
        fs: 'server.example.com:/exports/home'
```

---

## Concepts: how autofs works

Understanding autofs before configuring it will save you time. The model has
two layers:

```
autofs daemon
   |
   +-- /etc/auto.master        (the INDEX: "for this parent path, read this map file")
   |
   +-- /etc/auto.home          (the MAP:  "for this key, mount this filesystem")
```

**1. The master map (`/etc/auto.master`).** Each non-comment line has three
fields:

```
<parent path> <map file> [mount options]
/home /etc/auto.home --timeout=120
```

This line tells autofs: "when something looks under `/home`, use the map file
`/etc/auto.home`." The `/home` here is called an **automount point** (or the
*indirect map's mount point*). The master map never names a filesystem; it only
names a parent directory and the map file that describes what lives beneath it.

**2. The map file (`/etc/auto.home`).** Each line has the *sun* map format:

```
<key> <options> <source>
*   -rw,soft,intr  server.example.com:/exports/home
```

Here `key` is a **basename** (ie. a username), not a full path.
When a user `alice` touches `/home/alice`, autofs looks up the key `alice`
in `/etc/auto.home` and mounts the resulting source at `/home/alice`.
The special key `*` is the default ("wildcard") key used when no explicit
key matches.

Key terms:

* **Indirect map** - the map file's keys are basenames under a parent path (the
  `/home` example above). This is the common case.
* **Direct map** - the map uses `/-` as the parent path, and each key is a full
  absolute path (e.g. key `/opt/data` mounts at `/opt/data`). See
  [Direct maps](#direct-maps).
* **Timeout** - after a mount has been idle for `--timeout=<seconds>`
  (default 300), autofs unmounts it. Set per-mount-point options in the master
  map line, as in the `/home` example.

The module maps Puppet resources onto these two files. In short:

* `autofs::mount` writes the **master map** line (the automount point).
* `autofs::mapfile` / `autofs::mapping` write the **map file** contents.

This is why a working mount normally needs **both** an `autofs::mount` and a
`autofs::mapping` (or `autofs::mapfile`).

A common mistake is to declare only the `autofs::mount` and wonder why
nothing mounts.

---

## Common misconceptions and pitfalls

* **`autofs::mount` mounts a filesystem.** It does not. It declares an
  *automount point* in the master map ("for `/data`, read `/etc/auto.data`").
  The actual filesystems are declared with `autofs::mapping` /
  `autofs::mapfile`. Declaring only `autofs::mount` yields a master-map line and
  nothing else.

* **The `autofs::mount` *title* is the mount path.** The title is just a label
  (it names the drop-in file when `use_dir => true`). The real path is the
  `mount` parameter. Forgetting to set `mount => '/home'` produces an entry like
  `home /etc/auto.home` instead of `/home /etc/auto.home`.

* **Managing the master map / map files is all-or-nothing.** These resources are
  built on `concat`, so the file's content is fully reconstructed from what you
  declare. A hand-edited `/etc/auto.master` or map file is **overwritten** on the
  next run. Migrate existing entries first (see below), or set
  `manage_auto_master => false` and let the other tool own the file.

* **`use_dir` and `manage_auto_master` interact.** With
  `manage_auto_master => false`, `use_dir` *must* be `true`, or the catalog fails
  to compile. With `manage_auto_master => true`, `use_dir => true` also adds the
  `+dir:` line to the master map.

* **`autofs::mapfile` and `autofs::mount` are alternatives.** They are
  complementary, not competing: one is the index (master map), the other is the
  map content.

* **Declared types expect the `autofs` class in the catalog.**
  `autofs::mapfile` and `autofs::add_master_entry` read the class's parameters,
  but neither declares it: `autofs::mapfile` defaults `owner`/`group`/`mode` from
  `$autofs::map_file_owner/group/mode`, and `autofs::add_master_entry` defaults
  `master` from `$autofs::auto_master_map` and treats `$autofs::manage_auto_master`
  as a guard. `autofs::mount` pulls the class in itself (it calls `include 'autofs'`),
  while `autofs::mapping` reads no class parameters, yet it is what
  `autofs::mapfile` emits. Declaring any of them before the `autofs` class is
  declared leaves those references undefined and breaks compilation. Declare
  `class { 'autofs': }` (or at least `include autofs`) first.

* **A `+auto.master` (NIS) entry can be an `autofs::mount`.** It cannot; it is a
  master-map-only construct. Use `autofs::add_master_entry`.

* **`fs` and `mounts` are mutually exclusive in `autofs::mapping`.** Provide one
  or the other, never both.

* **Leading hyphens belong to the map format, not to the option string.**
  `autofs::mapping` `options` should be `ro` or `rw,soft`, not `-ro`. The module
  inserts the leading `-` for you.

* **Duplicate `(key, mapfile)` mappings** are not supported by
  `autofs::mapping`: declaring two `present` mappings with the same `key` in the
  same map file is a mistake. Both lines are written, and the earliest one in
  the file (the lowest `order`) is the one the module treats as effective.
  Declare each key once per map file.

---

## The `autofs` class: tuning what is managed

`class autofs (...)` is the only *public* class. Pulling it in installs and
starts the service. The most commonly used parameters are:

| Parameter | Default | Purpose |
| --- | --- | --- |
| `manage_auto_master` | `true` | Whether the module may write to `/etc/auto.master`. Set `false` when another tool owns the master map. |
| `package_ensure` | `installed` | State of the package: `installed`, `absent`, a version string. |
| `service_ensure` | `running` | State of the service: `running` or `stopped`. |
| `service_enable` | `true` | Enable on boot. |
| `auto_master_map` | `/etc/auto.master` | Master-map path (override for cross-platform). |
| `default_map_dir` | `/etc/auto.master.d` | Drop-in directory. |
| `map_file_owner` / `map_file_group` / `map_file_mode` | `root` / `root` / `0644` | Default ownership/mode for managed files. |
| `map_dir_mode` | `0755` | Mode for the drop-in directory. |
| `purge_map_dir` | `false` | Default of the purge and recurse attributes managing the drop-in directory. When true, unmanaged files in it are removed. |
| `mounts` | `{}` | Hash of `autofs::mount` entries (see [The defined types](#the-defined-types)). |
| `mapfiles` | `{}` | Hash of `autofs::mapfile` entries (see [The defined types](#the-defined-types)). |

To *not* manage a piece, turn it off:

```puppet
# Uninstall everything.
class { 'autofs':
  package_ensure => 'absent',
}

# Keep the package, but disable the service.
class { 'autofs':
  service_ensure => 'stopped',
  service_enable => false,
}
```

The full parameter list (including LDAP, watchdog services, and reload) is in
[REFERENCE.md](REFERENCE.md) under `class autofs`.

---

## The defined types

The module exposes **four public defined types**.

Three of them work in pairs (master map vs. map file); the fourth is for
master-map entries that are not mount points.

This section explains each one, how to use it in a manifest and in
Hiera, and - critically - what distinguishes it from the others.

### Which defined type do I use?

Use this table to pick the right resource.

| What you want to put... | In which file | Use... |
| --- | --- | --- |
| "When something looks under `/data`, use `/etc/auto.data`" | master map | `autofs::mount` |
| "Include a drop-in directory managed by a package I don't control" | master map | `autofs::add_master_entry` |
| "Include a central map from NIS (`+auto.master`)" | master map | `autofs::add_master_entry` |
| The file `/etc/auto.data` itself (its permissions, whether to replace it) | the map file | `autofs::mapfile` |
| One line `dataA -ro remote:/exports/dataA` inside `/etc/auto.data` | the map file | `autofs::mapping` |
| Several lines inside `/etc/auto.data` | the map file | `autofs::mapfile` with a `mappings` array |

A working indirect mount almost always uses **both** `autofs::mount` (the index
line) and `autofs::mapping`/`autofs::mapfile` (the map content).

### `autofs::mount` -- declare an automount point in the master map

`autofs::mount` declares **one entry in the master map**: "when something looks
under `<mount>`, consult `<mapfile>`." It never touches the *content* of that
map file. Think of it as declaring an *automount point*, not a filesystem.

Most-used parameters:

| Parameter | Default | Purpose |
| --- | --- | --- |
| `mapfile` | *(required)* | The map file autofs should read, e.g. `/etc/auto.home`. May also be a map *specification* such as `program:/usr/sbin/script` or `-hosts`. |
| `mount` | the resource title | The absolute parent path, e.g. `/home`. For a direct map, use `/-`. |
| `options` | `undef` | Mount options for this point, e.g. `--timeout=120`. |
| `use_dir` | `false` | Record the entry in a drop-in file under the master map's drop-in directory instead of directly in the master map. |
| `ensure` | `present` | `present` or `absent` (removes the entry from the master map). |
| `order` | `1` | Relative ordering of entries in the master map. |
| `ensure_dir` | `false` | Also create the drop-in directory (useful when the module does *not* own the master map). |

**Manifest:**

```puppet
autofs::mount { 'home':
  mount   => '/home',
  mapfile => '/etc/auto.home',
  options => '--timeout=120',
}
```

**Hiera** (part of the `mounts` hash; merge with `merge: hash`):

```yaml
autofs::mounts:
  home:
    mount: '/home'
    mapfile: '/etc/auto.home'
    options: '--timeout=120'
```

The resource `title` (here `home`) is an arbitrary label; the actual path comes
from `mount`. The title is used only to name the drop-in file when
`use_dir => true` (see below): `autofs::mount { 'misc' }` writes
`/etc/auto.master.d/misc.autofs`.

### `autofs::mapfile` -- manage a map file

`autofs::mapfile` manages **the contents of a single map file** (sun format),
and optionally its ownership, mode, and whether it overwrites an existing file.
It is the complement of `autofs::mount`: where `mount` names the map file in the
master map, `mapfile` writes that file's key-to-filesystem lines.

Most-used parameters:

| Parameter | Default | Purpose |
| --- | --- | --- |
| `path` | the resource title | Absolute path of the map file, e.g. `/etc/auto.home`. |
| `mappings` | `[]` | Array of mapping hashes (same shape as `autofs::mapping`). |
| `replace` | `true` | Replace the whole file. Set `false` to preserve content autofs/Puppet did not put there. |
| `owner` / `group` / `mode` | from the `autofs` class | File ownership/mode. |

`autofs::mapfile` takes a short cut: instead of declaring each mapping with a
separate `autofs::mapping` resource, pass them all in the `mappings` array.

Each element of the array is a mapping hash in exactly the same shape that
`autofs::mapping` takes, so the array is just a way to group a whole map file's
lines in one place.

Because every mapping defaults to `order 10`, you usually set an
explicit `order` when you want to guarantee a specific line's position, for
example keeping the wildcard default key last:

**Manifest:**

```puppet
autofs::mapfile { '/etc/auto.home':
  mappings => [
    { 'key' => 'root', 'options' => 'rw', 'fs' => 'server.example.com:/exports/root', 'order' => 10 },
    { 'key' => '*', 'options' => 'rw,soft,intr', 'fs' => 'server.example.com:/exports/home', 'order' => 20 },
  ],
}
```

which renders `/etc/auto.home` as

```sh
root -rw server.example.com:/exports/root
* -rw,soft,intr server.example.com:/exports/home
```

Grouping the lines in the `mappings` array is purely a
convenience for keeping a map file's content in a single resource; it produces
exactly the same file as declaring each entry as a separate `autofs::mapping`
that targets the same `autofs::mapfile`. You can even mix the two: declare a
`mappings` array for the bulk of the lines and add one-off entries with
`autofs::mapping` resources.

**Hiera** (part of the `mapfiles` hash; merge with `merge: hash`):

```yaml
autofs::mapfiles:
  '/etc/auto.home':
    mappings:
      - key: '*'
        options: 'rw,soft,intr'
        fs: 'server.example.com:/exports/home'
```

Because `autofs::mapfile` uses a `concat` resource internally, managing a map
file is **all-or-nothing**: the file's content is fully reconstructed from the
mappings you declare, so any lines you leave out are removed.

Setting `replace => false` preserves pre-existing lines below the managed banner instead.

### `autofs::mapping` -- declare a single mapping inside a map file

`autofs::mapping` declares **one line** inside a map file: `<key> <options>
<source>`. Use it when you prefer to spread mappings across many resources (or
Hiera keys), or when you want a dedicated resource per mount.

Each `autofs::mapfile` resource can host any number of `autofs::mapping`
resources. Every `autofs::mapping` must target a map file that also has an
`autofs::mapfile` resource, because the fragment it writes only takes effect
once that `concat` resource exists to build the file.

Most-used parameters:

| Parameter | Default | Purpose |
| --- | --- | --- |
| `mapfile` | *(required)* | The map file this mapping belongs to. |
| `key` | *(required)* | The autofs key: a basename for indirect maps, an absolute path for direct maps. |
| `fs` | *(one of `fs`/`mounts`)* | The filesystem to mount, e.g. `host.example.com:/export/path`. Accepts a string or an array of replicated sources. |
| `mounts` | *(one of `fs`/`mounts`)* | A **multi-mount** list (see [Multi-mount entries](#multi-mount-entries)). |
| `options` | `undef` | Mount options (string or array; a leading `-` is added automatically). |
| `ensure` | `present` | `present` or `absent`. |
| `order` | `10` | Relative ordering of mappings within the file. |

**Manifest:**

```puppet
autofs::mapping { '/mnt/data_dataA':
  mapfile => '/mnt/data',
  key     => 'dataA',
  options => 'ro',
  fs      => 'remote.com:/exports/dataA',
}
```

**Hiera:**

```yaml
autofs::mappings:
  '/mnt/data_dataA':
    mapfile: '/mnt/data'
    key: 'dataA'
    options: 'ro'
    fs: 'remote.com:/exports/dataA'
```

Two rules the type enforces:

* Provide either `fs` **or** `mounts`, never both.
* Do not declare two `present` mappings with the same `key` targeting the same
  map file -- if that happens, only the lowest `order` wins.

### `autofs::add_master_entry` -- add an arbitrary master-map entry

`autofs::add_master_entry` adds a line to the **master map** without declaring a
mount point. Use it when the entry is not an automount point you manage, for
example:

* a `+dir:` line pointing at a drop-in directory a package owns;
* a `+auto.master` line that pulls in a central map via nsswitch (NIS);
* any other raw master-map line you want Puppet to keep present.

Most-used parameters:

| Parameter | Default | Purpose |
| --- | --- | --- |
| `entry` | the resource title | The raw master-map line. |
| `ensure` | `present` | `present` or `absent`. |
| `ensure_dir` | `false` | For a `+dir:` entry, also create the referenced directory. |
| `order` | `50` | Relative ordering of entries in the master map. |

The `entry` defaults to the resource title, so the common case is terse:

```puppet
# +dir:/etc/auto.master.d/myapp
autofs::add_master_entry { '+dir:/etc/auto.master.d/myapp':
  ensure_dir => true,
}

# Pull in a central master map from NIS.
autofs::add_master_entry { 'nis_maps':
  entry => '+auto.master',
}
```

**Hiera:**

```yaml
autofs::add_master_entries:
  '+dir:/etc/auto.master.d/myapp':
    ensure_dir: true
  nis_maps:
    entry: '+auto.master'
```

`autofs::add_master_entry` refuses to run when `manage_auto_master` is `false`,
because it can only write to a master map the module owns.

---

## Migrating an existing `/etc/auto.master`

Because the module owns the master map completely, applying it to a
hand-maintained (or distro-shipped) `/etc/auto.master` would otherwise replace it.
The migration path is to redeclare each existing entry as an `autofs::mount`
with `use_dir => true`, so it lives in `/etc/auto.master.d/<title>.autofs`
instead of directly in the master map.

RHEL-family distributions have historically shipped `/etc/auto.master` with
these entries active (verify what the file you are migrating actually
contains):

```sh
/misc   /etc/auto.misc
/net    -hosts
+dir:/etc/auto.master.d
+auto.master
```

Convert each one. The `-hosts` entry is a built-in map (give it directly as the
`mapfile`); the `+dir:` line is not needed in a drop-in because the module
manages it in the master map itself; and a `+auto.master` line must use
`autofs::add_master_entry`.

```puppet
autofs::mount { 'misc':
  mount   => '/misc',
  mapfile => '/etc/auto.misc',
  use_dir => true,
}

autofs::mount { 'net':
  mount   => '/net',
  mapfile => '-hosts',
  use_dir => true,
}

# A central NIS master map cannot be an autofs::mount; carry it over as-is.
autofs::add_master_entry { '+auto.master':
  entry => '+auto.master',
}
```

```yaml
autofs::mounts:
  misc:
    mount: '/misc'
    mapfile: '/etc/auto.misc'
    use_dir: true
  net:
    mount: '/net'
    mapfile: '-hosts'
    use_dir: true
autofs::add_master_entries:
  '+auto.master':
    entry: '+auto.master'
```

The resulting master map becomes just the `+dir:/etc/auto.master.d` and
`+auto.master` lines, with `/misc` and `/net` living in their own drop-in
files.

---

## Advanced configuration


### Global automount options

Two class parameters feed the service config file's startup environment. That
file is only written when `manage_service_config => true`:

* `service_options` (array): appended to the `OPTIONS=` line passed to the
  `automount` daemon, e.g. `service_options => ['--ghost', '--ghost-permission 0755']`.
* `service_use_misc_device` (`'yes'`/`'no'`): sets `USE_MISC_DEVICE`, deciding
  whether autofs uses the kernel's misc device.

### LDAP-backed maps

When autofs reads its maps from LDAP instead of local files, two files need
configuration, and the module manages both (off by default):

1. **The service options** in the service config file (`/etc/sysconfig/autofs`
   on RHEL, `/etc/default/autofs` on Debian), enabled with
   `manage_service_config => true` and filled from `service_conf_options`. These
   tell automount *how to query* LDAP: the URI, the search base, and the
   attribute/class names that map LDAP entries onto maps and mounts.
2. **The auth/ACL settings** in `/etc/autofs_ldap_auth.conf`, enabled with
   `manage_ldap_auth_conf => true` and filled from `ldap_auth_config`. These
   control TLS and whether authentication is required.

```yaml
autofs::manage_service_config: true
autofs::service_conf_options:
  ENTRY_ATTRIBUTE: 'cn'
  ENTRY_OBJECT_CLASS: 'automount'
  LDAP_URI: 'ldap://ldap.example.org'
  MAP_ATTRIBUTE: 'ou'
  MAP_OBJECT_CLASS: 'automountMap'
  SEARCH_BASE: 'ou=automount,dc=autofs,dc=example,dc=org'
  VALUE_ATTRIBUTE: 'automountInformation'

autofs::manage_ldap_auth_conf: true
autofs::ldap_auth_config:
  usetls: 'yes'
  tlsrequired: 'yes'
  authrequired: 'no'
```

Both files carry a "managed by Puppet" banner. Note that `manage_service_config`
and `manage_ldap_auth_conf` are independent: you can manage one without the
other.

### Reloading without restarting (`reload_command`)

By default, whenever the master map or a managed map file changes, the module
restarts the autofs service to pick up the change. For systems where a full
restart is undesirable, set `reload_command` to a shell command; the module then
runs it (once, on change) instead of restarting:

```puppet
class { 'autofs':
  reload_command => '/usr/sbin/automount --remount-all',
}
```

### Owning versus not owning the master map

The `autofs::manage_auto_master` flag (default `true`) decides whether the module
is allowed to touch `/etc/auto.master`.

* **`true` (default):** the module manages the whole file. Any `autofs::mount`
  with `use_dir => false` is written directly into it, and any with
  `use_dir => true` adds a `+dir:` line. The content is all-or-nothing: entries
  you do not declare do not survive a run.
* **`false`** is for when another module, tool, or configuration-management
  system owns `/etc/auto.master`. The module then writes **nothing** to it. In
  this mode **every** `autofs::mount` *must* use `use_dir => true` (otherwise the
  catalog fails to compile), so its entry lands in a drop-in file the module
  still manages. The drop-in directory itself must be enabled by whoever owns
  the master map. If the platform's autofs package does not ship the drop-in
  directory, add `ensure_dir => true` to a mount (or to an
  `autofs::add_master_entry`) and the module creates it anyway.

```puppet
class { 'autofs':
  manage_auto_master => false,
}

autofs::mount { 'home':
  mount      => '/home',
  mapfile    => '/etc/auto.home',
  use_dir    => true,
  ensure_dir => true,
}
```

### Executable map files

A map file can be an **executable program** that prints mappings to stdout (or,
for multi-map mode, to stderr). The module sets map-file permissions from the
`autofs` class defaults; to force a map file to be executable, set its `mode`:

```puppet
autofs::mapfile { '/etc/auto.data':
  path => '/etc/auto.data',
  mode => '0755',
}
```

Refer to it from the master map with a `program:` prefix:

```puppet
autofs::mount { 'data':
  mount   => '/data',
  mapfile => 'program:/etc/auto.data',
}
```

### Drop-in directories and `+dir:`

With recent autofs, `/etc/auto.master` can enable a **drop-in directory**: a
single `+dir:/etc/auto.master.d` line tells autofs to read every `*.autofs`
file in that directory as though they were master-map lines. This is handy for
splitting the master map into small, owner-scoped files.

`autofs::mount` supports it via `use_dir => true`. Instead of writing a direct
line to `/etc/auto.master`, the entry is recorded in
`/etc/auto.master.d/<title>.autofs`, and the module adds the `+dir:` line:

```puppet
autofs::mount { 'home':
  mount   => '/home',
  mapfile => '/etc/auto.home',
  use_dir => true,
}
```

produces:

```sh
# /etc/auto.master
+dir:/etc/auto.master.d

# /etc/auto.master.d/home.autofs
/home /etc/auto.home
```

All `use_dir` mounts sharing a drop-in directory share the single `+dir:`
line: the first-evaluated mount configures it (and the directory when
`ensure_dir => true`), so mounts sharing a directory should agree on `order`
and `ensure_dir`.

`autofs::add_master_entry` can add `+dir:` lines for drop-in directories you do
not manage (see above).

### Purging unmanaged drop-in files

By default, files already present in the drop-in directory that Puppet does not
manage are left alone. Setting `purge_map_dir => true` makes it the default of
the purge and recurse attributes that `autofs::mapdir` applies to each drop-in
directory, so that files present but not declared elsewhere in the catalog are
removed. Note that the module only manages the directory itself -- and so only
purges it -- when `ensure_dir => true` is set (on an `autofs::mount` using
`use_dir`, or on a `+dir:` `autofs::add_master_entry`); with `use_dir` alone
the directory is left untouched.

### Direct maps

Indirect maps use basenames as keys under a parent path. A **direct map** uses
`/-` as the master-map parent, and each key is a full absolute path. To use a
direct map, set the `autofs::mount` `mount` parameter to `/-`:

```puppet
autofs::mount { 'root':
  mount   => '/-',
  mapfile => '/etc/auto.direct',
}

autofs::mapping { '/opt/data_primary':
  mapfile => '/etc/auto.direct',
  key     => '/opt/data',
  options => 'rw',
  fs      => 'nfs1.example.com:/exports/d1',
}
```

Because autofs requires direct-map keys to be absolute mount paths, and there is
no parent path to bind them to, **the module does not validate that your keys
are absolute paths**. Verify them yourself.

### Multi-mount entries

Sometimes one autofs key must mount **several** filesystems at once, each at its
own sub-path. Autofs calls this "Multiple Mounts" in [`autofs(5)`](https://man7.org/linux/man-pages/man5/autofs.5.html).
For example, one key `/data` might mount a read-only shared tree and a separate
read-write tree beneath `/data`:

```puppet
# The automount point, in the master map.
autofs::mount { 'data':
  mount   => '/data',
  mapfile => '/etc/auto.data',
  options => '--timeout=120',
}

# The multi-mount lines, inside the map file.
autofs::mapfile { '/etc/auto.data':
  mappings => [
    {
      key     => 'data',
      options => '--timeout=120',
      mounts  => [
        { 'fs' => 'nfs1.example.com:/exports/d1' },
        { 'mountpoint' => '/docs', 'options' => 'ro', 'fs' => 'nfs2.example.com:/exports/d2' },
      ],
    },
  ],
}
```

This produces:

```sh
# /etc/auto.master
/data /etc/auto.data --timeout=120

# /etc/auto.data
data --timeout=120 nfs1.example.com:/exports/d1 /docs -ro nfs2.example.com:/exports/d2
```

So a lookup of `data` mounts `nfs1` at the automount point `/data` and
(read-only) `nfs2` at `/data/docs`. Note that the first source is written
alone, with no `/` before it: omitting the `mountpoint` mounts the source at
the automount point itself, per autofs(5)'s "Multiple Mounts" form
`key [-options] [mount-point [-options] location...]`. Writing the `/`
explicitly would mount the same place, but produces a longer map line. Notes:

* The entry-level `options` (here `--timeout=120`) apply to every sub-mount,
  unless a sub-mount supplies its own `options`.
* Give each sub-mount a `mountpoint` (it is written verbatim, so it must start
  with `/`) to mount at a sub-path; omit it to mount that source at the
  automount point itself.
* Express it as an `autofs::mapping` (or a `mappings` element of `autofs::mapfile`)
  **plus** the `autofs::mount`. Never put `mounts` and `fs` in the same mapping.

---

## Limitations and deprecations

* `autofs::package` and `autofs::service` are **private** classes; declare the
  service or package state through the `autofs` class parameters instead.
* The `direct`, `executable`, `mapcontents`, `mapfile_manage`, and `replace`
  parameters of `autofs::mount` have been removed; use the current parameters
  instead.
* The older `autofs::map` defined type (and the `maps` class parameter) is no
  longer provided; declare map files via `autofs::mapfile` resources or the
  `mapfiles` class parameter.
* A mapfile whose `path` is the master map (and `manage_auto_master` is `true`)
  contributes only its mappings as `concat` fragments. Its `ensure`, `replace`,
  and `mode` parameters are **ignored** in that case, because the master map's
  `concat` is owned by the private `autofs::master` class and the module will not
  (and cannot) set those attributes on it there. To address the master map
  directly, use `autofs::add_master_entry` instead.

---

## Development

The full, machine-generated API reference is in [REFERENCE.md](REFERENCE.md).

Development follows the Vox Pupuli conventions shared across its modules:

* Unit tests use rspec-puppet (`spec/`); run with `rake spec`.
* Acceptance tests (`spec/acceptance`) provision nodes via
  [`voxpupuli-acceptance`](https://github.com/voxpupuli/test) (Beaker-based).
* CI runs on GitHub Actions (`.github/workflows/ci.yml`).

For the module's own metadata — its dependencies, supported operating systems,
and version requirements — see [metadata.json](metadata.json).

---

## Support and authors

For issues, feature requests, and documentation, see the project's home pages:

* Project site: https://voxpupuli.org/puppet-autofs
* GitHub: https://github.com/voxpupuli/puppet-autofs
* Puppet Forge: https://forge.puppet.com/puppet/autofs

Authors:

* Vox Pupuli: <voxpupuli@groups.io>
* David Hollinger III: <david.hollinger@moduletux.com>
