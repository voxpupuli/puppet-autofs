# Autofs Puppet Module

[![Build Status](https://github.com/voxpupuli/puppet-autofs/workflows/CI/badge.svg)](https://github.com/voxpupuli/puppet-autofs/actions?query=workflow%3ACI)
[![Release](https://github.com/voxpupuli/puppet-autofs/actions/workflows/release.yml/badge.svg)](https://github.com/voxpupuli/puppet-autofs/actions/workflows/release.yml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppet/autofs.svg)](https://forge.puppetlabs.com/puppet/autofs)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/puppet/autofs.svg)](https://forge.puppetlabs.com/puppet/autofs)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/autofs.svg)](https://forge.puppetlabs.com/puppet/autofs)
[![Puppet Forge - scores](https://img.shields.io/puppetforge/f/puppet/autofs.svg)](https://forge.puppetlabs.com/puppet/autofs)
[![puppetmodule.info docs](http://www.puppetmodule.info/images/badge.png)](http://www.puppetmodule.info/m/puppet-autofs)
[![Apache-2 License](https://img.shields.io/github/license/voxpupuli/puppet-autofs.svg)](LICENSE)

## Table of Contents

1. [Description - - What the module does and why it is useful](#description)
2. [Setup - The basics of getting started with Autofs](#setup)
  * [The module manages the following](#the-module-manages-the-following)
  * [Requirements](#requirements)
  * [Incompatibilities](#incompatibilities)
3. [Usage - Configuration options and additional functionality](#usage)
   * [Multi-mount entries](#multi-mount-entries)
4. [Limitations - OS compatibility, etc](#limitations)
5. [Development - Guide for contributing to the module](#development)
6. [Support - When you need help with this module](#support)

### Description

The Autofs module is a Puppet module for managing the configuration of on-demand mounting and
automatic unmounting of local and remote filesystems via autofs / automount. This is a global
module designed to be used by any organization.  It enables most details of Autofs
configuration to be specified via the user's choice of Puppet manifest or external data.

### Setup

The Module manages the following:

* Autofs package
* Autofs service
* Autofs master map (/etc/auto.master)
* Autofs map files (e.g. /etc/auto.home)

### Requirements

* The [stdlib](https://forge.puppetlabs.com/puppetlabs/stdlib) Puppet module
* The [concat](https://github.com/puppetlabs/puppetlabs-concat) Puppet module

### Usage

The module provides one public class:

```puppet
include autofs
```

This class manages the autofs package and service, and optionally the master
map (`/etc/auto.master`) and mount points.  When `manage_auto_master` is true
(the default), the module also declares the private `autofs::master` class to
set up the master map file for use with `autofs::add_master_entry` and
`autofs::mount` resources.

With all default parameter values, this installs, enables, and starts the
autofs service, configuring it to rely on the default location for the
master map.  If desired, the required state of the autofs package and / or
service can instead be specified explicitly via class parameters.  For example,

To ensure the package is absent:
```puppet
class { 'autofs':
  package_ensure => 'absent',
}
```

To ensure the service is disabled and not running:
```puppet
class { 'autofs':
  service_ensure => 'stopped',
  service_enable => false,
}
```

#### Master Map

The module provides two compatible, built-in mechanisms for managing the
content of the master map: by setting the `mounts` parameter of the `autofs`
class, and by declaration of `autofs::mount` resources.  Using these is not
obligatory -- one could instead use a `File` resource, for instance, but
using the built-in mechanisms automatically provides for the autofs service
to be notified of any changes to the master map.

Note well, however, that managing the master map via this module's built-in
mechanisms is an all-or-nothing affair.  If any autofs mount points are managed
via either of those mechanisms, then *only* mount points managed via those
mechanisms will appear in the master map.

Before applying this module to a system with an existing, hand-maintained
`/etc/auto.master`, see [Migrating an existing /etc/auto.master](#migrating-an-existing-etcautomaster)
below.

##### example

The declaration

```puppet
autofs::mount { 'home':
  mount       => '/home',
  mapfile     => '/etc/auto.home',
  options     => '--timeout=120'
}
```

, or the equivalent element of the value of class parameter
`$autofs::mounts`, will result in the following entry in the master
map"

```sh
/home /etc/auto.home --timeout=120
```

The target map file, `/etc/auto.home`, is not affected by this.

Alternatively, this can be expressed directly in the declaration of
class `autofs`:

```puppet
class { 'autofs':
  mounts => {
    'home' => {
      'mount'   => '/home',
      'mapfile' => '/etc/auto.home',
      'options' => '--timeout=120'
    }
  }
}
```

or in YAML form in external Hiera data:

```yaml
lookup_options:
  autofs::mounts:
    merge: hash
autofs::mounts:
  home:
    mount: '/home'
    mapfile: '/etc/auto.home'
    options: '--timeout=120'
```

For more information about merge behavior see the doc for:

* [Lookup docs](https://docs.openvoxproject.org/openvox/latest/hiera_quick.html)

#### Direct Map `/-` argument

The autofs module supports Autofs direct maps naturally.  For a direct map,
simply specify the `mount` parameter as `/-`, just as is used for the purpose
in the `auto.master` file.  When this option is exercised, Autofs requires
the keys in the corresponding map file to be absolute paths of mountpoint
directories; this module does *not* validate that constraint.

##### example

Define:

```puppet
autofs::mount { 'foo':
  mount       => '/-',
  mapfile     => '/etc/auto.foo',
  options     => '--timeout=120',
}
```

Hiera:

```yaml
autofs::mounts:
  foo:
    mount: '/-'
    mapfile: '/etc/auto.foo'
    options: '--timeout=120'
```

#### `+dir:` drop-in directories

The autofs module supports the use of Autofs's `+dir:` option (Autofs 5.0.5
or later) to record master map content in drop-in files in a specified
directory instead of directly in the master map.

By default a `mount` is written *directly* into the master map: `use_dir`
defaults to `false`.  Set `use_dir => true` to instead record the entry as a
separate drop-in file (for example `/etc/auto.master.d/home.autofs`).  The
`+dir:` line that enables the drop-in directory is managed only when the
master map itself is managed -- that is, when `use_dir` is `true` *and* the
`autofs` class parameter `manage_auto_master` is still `true` (the default).
When `manage_auto_master` is `false` the module never writes to the master
map, so it does not add the `+dir:` line; set `ensure_dir => true` to make the
directory exist and let the owner of the master map enable the drop-in
directory.  Internally, this uses the `autofs::add_master_entry` defined type
to manage the master map entry.

##### example

Define:

```puppet
autofs::mount { 'home':
  mount       => '/home',
  mapfile     => '/etc/auto.home',
  options     => '--timeout=120',
  use_dir     => true
}
```

Hiera:

```yaml
autofs::mounts:
  home:
    mount: '/home'
    mapfile: '/etc/auto.home'
    options: '--timeout=120'
    use_dir: true
```

#### Managing master map entries independently

If you need to add an entry to the master map without managing a corresponding
mount point (for example, when a package drops files into a drop-in directory
that you don't manage through Puppet, or when you need an entry other than
`+dir:`), use the `autofs::add_master_entry` defined type.

This ensures the specified entry appears in `/etc/auto.master`, but does not
manage any map files or mount points.

##### example

Add a `+dir:` entry for a drop-in directory managed externally (title defaults
to entry):

```puppet
autofs::add_master_entry { '+dir:/etc/auto.master.d/myapp': }
```

With `ensure_dir => true`, also ensure the directory exists:

```puppet
autofs::add_master_entry { '+dir:/etc/auto.master.d/myapp':
  ensure_dir   => true,
}
```

Or specify the entry explicitly:

```puppet
autofs::add_master_entry { 'myapp':
  entry => '+dir:/etc/auto.master.d/myapp',
}
```

Add an arbitrary master map entry (e.g., NIS map inclusion):

```puppet
autofs::add_master_entry { 'nis_maps':
  entry => '+auto.master',
}
```

Hiera:

```yaml
autofs::add_master_entry:
  '+dir:/etc/auto.master.d/myapp':
    ensure_dir: true
  nis_maps:
    entry: '+auto.master'
```

This approach is cleaner than using a dummy `autofs::mount` with `use_dir`
when you only need an entry without any mounts. The title defaults to the
entry content, simplifying the common case of `+dir:` entries.

#### Declining to manage the master map directly

Sometimes the master map is owned by another module, tool, or configuration
management system, and this module must not write to it at all.  Setting the
class parameter `manage_auto_master` to `false` disables all direct
management of the master map: the module will neither create the file nor
write entries or `+dir:` lines into it.  Every `autofs::mount` must then use
`use_dir => true`, so its entry is recorded as a drop-in file (which this
module does continue to manage) in the drop-in directory.  In that case, it
is the responsibility of whoever owns the master map to ensure the directory
is enabled, either via a `+dir:` entry or by relying on a build of autofs
that reads the drop-in directory automatically.  Any `autofs::mount` left
with `use_dir => false` under this setting fails compilation rather than
silently doing nothing.

If the drop-in directory is not provided by the platform's autofs package,
add `ensure_dir => true` to a mount (or to an `autofs::add_master_entry`
for a `+dir:` entry) and the module will ensure the directory itself,
even while leaving the master map untouched.

##### example

```puppet
class { 'autofs':
  manage_auto_master => false,
}

autofs::mount { 'home':
  mount       => '/home',
  mapfile     => '/etc/auto.home',
  options     => '--timeout=120',
  use_dir     => true,
}
```

Hiera:

```yaml
autofs::manage_auto_master: false
autofs::mounts:
  home:
    mount: '/home'
    mapfile: '/etc/auto.home'
    options: '--timeout=120'
    use_dir: true
```

Note that an explicitly declared `autofs::mapfile` resource whose `path` is
the master map is a direct, deliberate statement of intent and is not
affected by `manage_auto_master`.

#### Migrating an existing /etc/auto.master

Because the module owns the master map completely, applying it to a system
whose `/etc/auto.master` was maintained by hand (or shipped by the
distribution's autofs package) would otherwise replace that file's content.
The way to preserve existing entries is to declare each of them as an
`autofs::mount` with `use_dir => true`, so the entry lives in a drop-in file
under `/etc/auto.master.d` instead of directly in the master map.  The
resource title names the drop-in file: a resource titled `misc` becomes
`/etc/auto.master.d/misc.autofs`, matching the `*.autofs` convention used by
`+dir:`.

For example, the `/etc/auto.master` shipped with recent systemd-based
distributions contains these active entries:

```sh
/misc   /etc/auto.misc
/net    -hosts
+dir:/etc/auto.master.d
+auto.master
```

plus a commented-out example for FedFS support:

```sh
#/nfs4  /usr/sbin/fedfs-map-nfs4 nobind
```

Convert each entry -- and the commented FedFS example, if FedFS is wanted --
by declaring a `use_dir` mount for it.  The `-hosts` and `+dir:` lines need
special mention: `-hosts` is a built-in map and can be given directly as the
`mapfile`, while the `+dir:` line is not needed in any drop-in because the
module manages it in the master map itself.

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

# The distribution ships this entry commented out; declare it the
# same way to enable it.  An absolute path is treated by autofs as
# an executable program map; spelling it explicitly with the
# equivalent 'program:/usr/sbin/fedfs-map-nfs4' works too.
autofs::mount { 'nfs4':
  mount   => '/nfs4',
  mapfile => '/usr/sbin/fedfs-map-nfs4',
  options => 'nobind',
  use_dir => true,
}
```

The equivalent Hiera data:

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
  nfs4:
    mount: '/nfs4'
    mapfile: '/usr/sbin/fedfs-map-nfs4'
    options: 'nobind'
    use_dir: true
```

The resulting files are then

```sh
# /etc/auto.master
+dir:/etc/auto.master.d
```

```sh
# /etc/auto.master.d/misc.autofs
/misc /etc/auto.misc
```

```sh
# /etc/auto.master.d/net.autofs
/net -hosts
```

```sh
# /etc/auto.master.d/nfs4.autofs
/nfs4 /usr/sbin/fedfs-map-nfs4 nobind
```

Notes:

* A `+auto.master` line (which pulls in a central master map via nsswitch,
  e.g. NIS) cannot be expressed as an `autofs::mount`.  Use `autofs::add_master_entry`
  to carry over such entries:

  ```puppet
  autofs::add_master_entry { '+auto.master':
    entry => '+auto.master',
  }
  ```

  Or in Hiera:

  ```yaml
  autofs::add_master_entry:
    '+auto.master':
      entry: '+auto.master'
  ```

* By default, files already present in `/etc/auto.master.d` that Puppet does
  not manage are left in place.  Set `autofs::purge_map_dir` to `true` to
  have the module remove such leftovers, keeping the drop-in directory
  strictly mirrored to the declared mounts.

#### Removing mount points

Unwanted mount points can be ensured `absent` to force their removal from
`auto.master`.

##### example

Define:

```puppet
autofs::mount { 'home':
  ensure      => 'absent',
  mount       => '/home',
  mapfile     => '/etc/auto.home',
}
```

Hiera:

```yaml
autofs::mounts:
  home:
    ensure: 'absent'
    mount: '/home'
    mapfile: '/etc/auto.home'
```

#### Map Files

The module also provides two compatible, built-in mechanisms for managing
Autofs map files: by setting the `mapfiles` parameter of the `autofs`
class, and by declaration of `autofs::mapfile` resources.  As with entries
in the master map, using these is not obligatory.  In fact, they are
applicable only to map files written in the default (sun) map format;
some other mechanism must be chosen if map files in some other format are
to be managed.

As with the master map, managing map files via this module's built-in
mechanisms is an all-or-nothing affair.  If a map file is managed via these
mechanisms then only mappings declared via these mechanisms will be included.

Note that map file management is wholly independent of master map management.
Just as managing mount points in the master map does not affect corresponding
map files, managing map files does not affect the master map.

For example,

```puppet
autofs::mapfile { 'home':
  path     => '/etc/auto.home',
  mappings => [
    { 'key' => '*', 'options' => 'rw,soft,intr', 'fs' => 'server.example.com:/path/to/home/shares' }
  ]
}
```

The standard external-data representation again is associated with the module
via a parameter of class `autofs`:

```yaml
autofs::mapfiles:
  home:
    path: '/etc/auto.home'
    mappings:
      - key: '*'
        options: 'rw,soft,intr'
        fs: 'server.example.com:/path/to/home/shares'
```

Whichever form is used, the resulting mapping in file `/etc/auto.home` is

```sh
* -rw,soft,intr server.example.com:/path/to/home/shares
```

#### Executable map files

The owner, group, and mode defaults for map files correspond to class
parameters (`autofs::map_file_mode`, `autofs::map_file_owner`, and
`autofs::map_file_group`).

If a map file must be executable, you can set the `mode` parameter
to enforce `0755`.


```puppet
autofs::mapfile { 'home':
  path => '/etc/auto.data',
  mode => '0755'
}
```

#### Multiple mappings in the same file

Multiple mappings may be declared for the same map file, either in the same
`autofs::mapfile` resource (or an entry in the `autofs::mappings` class
parameter or corresponding external data), or in one or more separate
`autofs::mapping` resources:

```puppet
autofs::mapfile { '/mnt/data':
}

autofs::mapping { '/mnt/data_dataA':
  mapfile => '/mnt/data',
  key     => 'dataA',
  options => 'ro',
  fs      => 'remote.com:/exports/dataA'
}

autofs::mapping { '/mnt/data_dataB':
  mapfile => '/mnt/data',
  key     => 'dataB',
  options => 'rw,noexec',
  fs      => 'remote.com:/exports/dataB'
}
```

The resulting content of file `/mnt/data` would be

```sh
dataA -ro remote.com:/exports/dataA
dataB -rw,noexec remote.com:/exports/dataB
```

##### Hiera

The same map can be defined entirely through external Hiera data via the
`autofs::mapfiles` class parameter, with all of a file's mappings in that
file's `mappings` array:

```yaml
autofs::mapfiles:
  '/mnt/data':
    mappings:
      - key: 'dataA'
        options: 'ro'
        fs: 'remote.com:/exports/dataA'
      - key: 'dataB'
        options: 'rw,noexec'
        fs: 'remote.com:/exports/dataB'
```

That form places all of a map file's mappings in one Hiera location.  You
can also split the mappings across multiple Hiera files and merge them; see
[Hiera](https://docs.openvoxproject.org/openvox/latest/hiera_intro.html) for
details.  A `autofs::mapfile` entry (or resource) is still required for each
managed map file, and `autofs::mapping` entries only attach fragments to it.

#### Multi-mount entries

Sometimes a single Autofs key must mount **several filesystems at once**, each
under its own subdirectory, instead of a single source. Autofs calls this a
**multi-mount** entry, described under "**Multiple Mounts**" in
[`autofs(5)`](https://man7.org/linux/man-pages/man5/autofs.5.html).

A common case is an automount point that aggregates several backing shares
beneath one key. For example, one key `/data` can mount a read-only shared
directory and a separate read-write directory from a different server, all
beneath `/data`. Each sub-mount can carry its own mount options, while options
given at the entry level apply to every sub-mount that does not override them.

You would reach for a multi-mount when one key maps to more than one
filesystem, for instance:

* aggregating several NFS exports beneath a single mount point;
* giving different subdirectories different options (read-only versus
  read-write);
* mounting a tree that no single export can provide on its own.

##### Why it is expressed as a map file entry, not an `autofs::mount`

It is natural to think of a multi-mount as a kind of *mount*, but in Autofs the
concept is split across **two files**, so the module expresses it with two
resources:

* **The automount point** lives in the master map (`/etc/auto.master`). The
  `autofs::mount` resource manages only this: it says "when something looks up
  `/data`, use the map file `/etc/auto.data`." It never touches the contents of
  that map file.
* **The multi-mount line itself** lives *inside* the map file
  (`/etc/auto.data`). It is one key that lists several
  `[mountpoint] [ -options ] source` triples.

Because a complete multi-mount must exist in both the master map and the map
file, no single resource can describe it. This is why the several filesystems
are declared as an `autofs::mapping` (or as a `mappings` element of
`autofs::mapfile`) rather than as an `autofs::mount`. The `autofs::mount`
resource continues to declare the automount point; the `autofs::mapping`
resource declares the multiple filesystems under that point. The two pieces
belong together but live in two different files.

##### Declaring a multi-mount

The preferred form collects the map file and its mappings together via
`autofs::mapfile`, and declares the automount point separately with
`autofs::mount`:

```puppet
autofs::mount { 'data':
  mount       => '/data',
  mapfile     => '/etc/auto.data',
  options     => '--timeout=120',
}

autofs::mapfile { '/etc/auto.data':
  mappings => [
    {
      key     => 'data',
      options => '--timeout=120',
      mounts  => [
        { 'mountpoint' => '/',            'fs' => 'nfs1.example.com:/exports/d1' },
        { 'mountpoint' => '/docs', 'options' => 'ro', 'fs' => 'nfs2.example.com:/exports/d2' },
      ],
    },
  ],
}
```

This produces the master map entry

```sh
/data /etc/auto.data --timeout=120
```

and the map file `/etc/auto.data`

```sh
data --timeout=120 / nfs1.example.com:/exports/d1 /docs -ro nfs2.example.com:/exports/d2
```

When Autofs looks up the `data` key it mounts the first source at the automount
point `/data`, and the second at `/data/docs` (read-only). Note that `/data`
carries only the entry-level `--timeout=120`, while `/data/docs` adds its own
`ro` option.

The equivalent Hiera data:

```yaml
autofs::mounts:
  data:
    mount:   '/data'
    mapfile: '/etc/auto.data'
    options: '--timeout=120'
autofs::mapfiles:
  '/etc/auto.data':
    mappings:
      - key: 'data'
        options: '--timeout=120'
        mounts:
          - { 'mountpoint' => '/',  'fs' => 'nfs1.example.com:/exports/d1' }
          - { 'mountpoint' => '/docs', 'options' => 'ro', 'fs' => 'nfs2.example.com:/exports/d2' }
```

If you prefer to spread mappings across resources or Hiera files, declare the
map file once and attach the multi-mount as a standalone `autofs::mapping`
instead:

```puppet
autofs::mapfile { '/etc/auto.data': }

autofs::mapping { '/etc/auto.data_data':
  mapfile => '/etc/auto.data',
  key     => 'data',
  options => '--timeout=120',
  mounts  => [
    { 'mountpoint' => '/',            'fs' => 'nfs1.example.com:/exports/d1' },
    { 'mountpoint' => '/docs', 'options' => 'ro', 'fs' => 'nfs2.example.com:/exports/d2' },
  ],
}
```

##### Notes on the `mounts` elements

* Provide either `fs` or `mounts` for a mapping, never both. `fs` is for a
  single-mount entry (it may still be an array of replicated/weighted sources);
  `mounts` is for a multi-mount entry.
* Each `mounts` element is one source with an optional `mountpoint` and
  `options`:
  * `mountpoint` is written to the map file **verbatim**, so it must begin with
    `/` (for example `/docs`). To mount at the automount point itself, omit it
    by setting `mountpoint` to `undef` -- the source is then emitted alone,
    with no leading space.
  * `options` is the per-mountpoint option list; the mapping's `options` apply
    to every sub-mount unless overridden here.
* A source containing spaces is quoted automatically, just as with
  single-mount entries.

#### Removing Entries

To remove entries from a managed `mapfile` simply remove the element
from the `mappings` array in your manifest or external data.  If the
mapping is expressed via a separate `autofs::mapping` declaration, then
either omit that resource or ensure it `absent`:

Example:

```puppet
autofs::mapping { 'data':
  ensure      => 'absent',
  mapfile     => '/etc/auto.data',
  key         => 'dataA'
  fs          => 'example.com:/exports/dataA'
}
```

#### LDAP configuration

To setup autofs with an LDAP backend, some additional options need to be added to apply LDAP settings to the autofs configuration.  The first involves the `/etc/auth_ldap.conf` configuration file using the `$ldap_auth_config` hash.  The second is configuring the service itself with the service configuration file (in `/etc/default` or `/etc/sysconfig` depending on the operating system) using `$service_conf_options`.  It is also necessary to enable managing of these two files, which are not managed by default, using `$manage_ldap_auth_conf` and `$manage_service_config`.

##### example

```yaml
autofs::ldap_auth_config:
  usetls: 'yes'
  tlsrequired: 'yes'
  authrequired: 'no'
autofs::manage_ldap_auth_conf: true
autofs::manage_service_config: true
autofs::service_conf_options:
  ENTRY_ATTRIBUTE: 'cn'
  ENTRY_OBJECT_CLASS: 'automount'
  LDAP_URI: 'ldap://ldap.example.org'
  MAP_ATTRIBUTE: 'ou'
  MAP_OBJECT_CLASS: 'automountMap'
  SEARCH_BASE: 'ou=automount,dc=autofs,dc=example,dc=org'
  VALUE_ATTRIBUTE: 'automountInformation'
```

## Limitations

### Removals

Directly calling the `autofs::package` and `autofs::service` classes is disabled in 3.0.0.
These are now private classes.

The `direct`, `executable`, `mapcontents`, `mapfile_manage`, and `replace` parameters of
`autofs::mount` are removed in 5.0.0, the first having already been ineffective in 4.3.0,
and the others no longer being relevant starting in 5.0.0.

The `autofs::map` defined type, and the `maps` parameter of the `autofs` class that
declared it, are removed in 10.0.0.  Define map files via `autofs::mapfile` resources, or via
the `mapfiles` class parameter, instead.

## Development

Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for instructions regarding development environments and testing.

## Authors

* Vox Pupuli: [voxpupuli@groups.io](mailto:voxpupuli@groups.io)
* David Hollinger: [david.hollinger@moduletux.com](mailto:david.hollinger@moduletux.com)
