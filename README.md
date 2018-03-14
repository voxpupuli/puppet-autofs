Autofs Puppet Module
====================

[![Travis branch](https://img.shields.io/travis/voxpupuli/puppet-autofs/master.svg?style=flat-square)](https://travis-ci.org/voxpupuli/puppet-autofs)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppet/autofs.svg?style=flat-square)](https://forge.puppetlabs.com/puppet/autofs)
[![Puppet Forge](https://img.shields.io/puppetforge/dt/puppet/autofs.svg?style=flat-square)](https://forge.puppet.com/puppet/autofs)
[![Puppet Forge](https://img.shields.io/puppetforge/e/puppet/autofs.svg?style=flat-square)](https://forge.puppet.com/puppet/autofs)
[![Puppet Forge](https://img.shields.io/puppetforge/f/puppet/autofs.svg?style=flat-square)](https://forge.puppet.com/puppet/autofs)

#### Table of Contents
1. [Description - - What the module does and why it is useful](#description)
2. [Setup - The basics of getting started with Autofs](#setup)
  * [The module manages the following](#the-module-manages-the-following)
  * [Requirements](#requirements)
  * [Incompatibilities](#incompatibilities)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
4. [Limitations - OS compatibility, etc](#limitations)
5. [Development - Guide for contributing to the module](#development)
6. [Support - When you need help with this module](#support)

Description
-----------
The Autofs module is a Puppet module for managing the configuration of on-demand mounting and
automatic unmounting of local and remote filesystems via autofs / automount. This is a global
module designed to be used by any organization.  It enables most details of Autofs
configuration to be specified via the user's choice of Puppet manifest or external data.

Setup
-----
### The Module manages the following:
* Autofs package
* Autofs service
* Autofs master map (/etc/auto.master)
* Autofs map files (e.g. /etc/auto.home)

### Requirements

* The [stdlib](https://forge.puppetlabs.com/puppetlabs/stdlib) Puppet module
* The [concat](https://github.com/puppetlabs/puppetlabs-concat) Puppet module

### Usage

The module provides one class:

```puppet
include autofs
```

By default, this installs, enables, and starts the autofs service with the module's default master
map.  If desired, the required state of the autofs package and / or service can instead be specified explicitly
via class parameters.  For example,

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

### Map Files

This module provides several ways to manage Autofs map files.  In the first place, there is a defined type serving this purpose:
```puppet
autofs::mount { 'home':
  mount       => '/home',
  mapfile     => '/etc/auto.home',
  mapcontents => ['* -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl server.example.com:/path/to/home/shares'],
  options     => '--timeout=120',
  order       => 01
}
```
This example will generate content in both the auto.master file and the auto.home map
file:

##### auto.master
```
/home /etc/auto.home --timeout=120
```

##### auto.home
```
* -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl server.example.com:/path/to/home/shares
```

The same configuration can be achieved by specifying the same details in external data, as one element of a hash of hashes with key `autofs::mounts`. For example:
```yaml
autofs::mounts:
  home:
    mount: '/home'
    mapfile: '/etc/auto.home'
    mapcontents:
      - '* -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl server.example.com:/path/to/home/shares'
    options: '--timeout=120'
    order: 01
```

If `autofs::mounts` data from multiple files or hierarchy levels need to be combined, then hash-merge behavior for this key
should be specified via the `lookup_options` key:

```yaml
lookup_options:
  autofs::mounts:
    merge: hash
autofs::mounts:
  home:
    mount: '/home'
    mapfile: '/etc/auto.home'
    mapcontents:
      - '* -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl server.example.com:/path/to/home/shares'
    options: '--timeout=120'
    order: 01
```

For more information about merge behavior see the doc for:

* [Lookup docs](https://docs.puppet.com/puppet/4.7/lookup_quick.html#puppet-lookup:-quick-reference-for-hiera-users) 
* [Hiera 5 docs](https://docs.puppet.com/puppet/5.1/hiera_merging.html) if using Puppet >= 4.9

##### Direct Map `/-` arugment

The autofs module supports Autofs direct maps naturally.  For a direct map, simply specify the `mount` parameter as `/-`,
just as is used for the purpose in the `auto.master` file.  When this option is exercised, Autofs requires the keys in the
corresponding map file to be absolute paths of mountpoint directories; this module does *not* validate that constraint.

###### Examples:

Define:
``` puppet
autofs::mount { 'foo':
  mount       => '/-',
  mapfile     => '/etc/auto.foo',
  mapcontents => ['/foo -o options /bar'],
  options     => '--timeout=120',
  order       => 01
}
```

Hiera:
``` yaml
autofs::mounts:
  foo:
    mount: '/-'
    mapfile: '/etc/auto.foo'
    mapcontents:
      - '/foo -o options /bar'
    options: '--timeout=120'
    order: 01
```

##### Autofs `+dir:` options

The autofs module supports the use of Autofs's `+dir:` option (Autofs 5.0.5 or later) in the `auto.master` file to
incorporate the contents of all files from a specified directory into the master map's own logical content.  When a
`mount`'s `use_dir` parameter is `true` (default is `false`), the corresponding `auto.master` content is created as a
separate file in the appropriate directory instead of being written directly into `auto.master`.  `auto.master` is,
however, ensured to contain an appropriate `+dir:` entry designating the chosen fragment directory.

###### Usage

Define:
```puppet
autofs::mount { 'home':
  mount       => '/home',
  mapfile     => '/etc/auto.home',
  mapcontents => ['* -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl server.example.com:/path/to/home/shares'],
  options     => '--timeout=120',
  order       => 01,
  use_dir     => true
}
```

Hiera:
```yaml
autofs::mounts:
  home:
    mount: '/home'
    mapfile: '/etc/auto.home'
    mapcontents:
      - '* -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl server.example.com:/path/to/home/shares'
    options: '--timeout=120'
    order: 01
    use_dir: true
```

#### Map Entries
As an alternative to adding map entries via the `mapcontents` parameter of an `autofs::mount`, there is an `autofs::map`
type that serves the purpose as well.

##### Usage

Define:
```puppet
autofs::map{'data':
  mapfile     => '/etc/auto.data',
  mapcontents => 'data -user,rw,soft server.example.com:/path/to/data,
}
```

Hiera:
```yaml
autofs::maps:
  data:
    mapfile: '/etc/auto.data'
    mapcontent: 'data -user,rw server.example.com:/path/to/data'
```

It is assumed in this case that the map file itself is managed separately, such as via an `autofs::mount` resource.

```puppet
autofs::mount{'auto.data':
  mapfile => '/etc/auto.data',
  mount   => '/big',
}
```

##### Removing Entries

To remove entries from a `mapfile` simply remove the element from the `mapcontents` array in your manifest or external data.

Example:

```puppet
autofs::map {'data':
  mapfile     => '/etc/auto.data',
  mapcontents => [ 'dataA -o rw /mnt/dataA', 'dataB -o rw /mnt/dataB' ]
}
```

```yaml
autofs::maps:
  data:
    mapfile: '/etc/auto.data'
    mapcontents:
      - 'dataA -o rw /mnt/dataA'
      - 'dataB -o rw /mnt/dataB'
```

To remove the `dataA` entry from the `/etc/auto.data`, simply remove that array element:

```puppet
autofs::map {'data':
  mapfile     => '/etc/auto.data',
  mapcontents => [ 'dataB -o rw /mnt/dataB' ]
}
```

```yaml
autofs::maps:
  data:
    mapfile: '/etc/auto.data'
    mapcontents:
      - 'dataB -o rw /mnt/dataB'
```

**NOTE: Do NOT set `ensure => 'absent'` unless your intent is to remove the entire `mapfile`!**


## Reference

### Classes

#### Public Classes

* `autofs`: Main class. Contains or calls all other classes or defines.

#### Private Classes

* `autofs::package`: Handles autofs packages.
* `autofs::service`: Handles the service.

### Parameters

#### `mounts`

Optional.

Data type: Hash

A hash of options that describe contents of the master map, and possibly of individual map files.  Each entry is equivalent
to the title and a hash of the parameters of one `autofs::mount` resource.

#### `package_ensure`

Data type: String

Determines the required state of the autofs package. Can be set to: `installed`, `absent`, `lastest`, or a specific
version string.

Default: 'installed'

#### `service_ensure`

Data type: Enum['running', 'stopped']

Determines required state of the autofs service.

Default: 'running'

#### `service_enable`

Data type: Boolean

Determines whether the autofs service should start at system boot.

Default: `true`

### Defines

#### Public Defines

* `autofs::mount`: Describes an entry in the master map, and, optionally, some of or all of the contents of the corresponding
  map file.
* `autofs::map`: Describes a map file and some or all of its contents.

### Parameters for autofs::mount

#### `ensure`

Data type: String

The desired state of the mount definition in the master map.  If set to `absent`, the resulting master map will not
contain a mountpoint definition corresponding to this resource, nor will it cause a map file or any map file content
to be managed (but such content could still be created and managed via `autofs::map` resources or *other*
`autofs::mount` resources). Defaults to `present`.

#### `mount`

Data type: Stblib::Absolutepath

The Autofs mountpoint described by this resource.  When this parameter has the value `/-`, this resource describes a direct
mount, and the keys in the corresponding map file must be absolute paths to mountpoint directories.  Otherwise, this
resource describes an indirect map, and this parameter is a base path to the automounted directories
described by the corresponding map file.   Defaults to the `title` of this `autofs::mount`.

#### `mapfile`

Optional.

Data type: Stdlib::Absolutepath or Autofs::MapEntry

This parameter designates the automount map serving this mount.  Autofs supports a variety of options
here, but most commonly this is either an absolute path to a map file or the special string `-hosts`.
If its value is anything other than a plain absolute path, then the `mapfile_manage` parameter must take the
value `false`, and the specified mapfile must be managed separately.

This parameter corresponds to content in the master map.  If `mapfile_manage` is `true` (its default), then
the presence of this parameter also causes the corresponding map file to be created and managed.

#### `mapfile_manage`

Data type: Boolean

If true the the mapfile file will be created and maintained. Set this to `false` when the map file is maintained
some other way, e.g. `auto.smb` from the autofs package.

Default: true

#### `mapcontents`

Data type: Array or String

This string or each element of this array describes one filesystem to be configured for automounting.  It contributes to
map file content.  See the documentation of `$autofs::map::mapcontents` for more details.

Default: []

#### `options`

Optional.

Data type: String

This Mapping describes the auto.master options to use (if any)
when mounting the automounts.

Default: ''

#### `order` 

Data type: Integer

This Mapping describes where in the auto.master file the entry will
be placed. Order CANNOT be duplicated.

Default: `undef`

#### `master`

Data type: Stdlib::Absolutepath

This Parameter sets the path to the auto.master file.

Default: '/etc/auto.master'

#### `map_dir`

Data type: Stdlib::Absolutepath

This Parameter sets the path to the Autofs configuration directory
for map files. Applies only to autofs 5.0.5 or later. 

Default: '/etc/auto.master.d'

#### `use_dir`

Data type: Boolean

This Parameter tells the module if it is going to use $map_dir.

Default: `false`

#### `direct`

Deprecated.

Data type: Boolean

Retained for backwards compatibility, but has no effect.

Default: `true`

#### `execute`

Data type: Boolean

Whether the mapfile should be an executable shell script.

Default: `false`

#### `replace`

Data type: Boolean

Whether to replace the mapfile if it already exists.

Default: `true`

### Parameters for autofs::map

#### `ensure`

Data type: String

Ensures the state of the `mapfile`. Setting to `absent` **WILL REMOVE THE MAPFILE**. If you just
to remove an entry in the `mapfile`, remove the `mapcontents` string or array element you want to remove.

Default: 'present'

#### `mapfile`

Data type: Stdlib::Absolutepath

The autofs map file managed to which this resource provides contents. e.g '/etc/auto.data'.

#### `mapcontents`

Data type: String or Array

Each string corresponds to one line of the map file.

For non-executable map files, such a line should describe one filesystem mapping, in automount format.  There
are three whitespace-delimited fields: an identifying "key", which automount combines with the base path for
this map to form the mount path; the mount options as a comma-delimited string; and the remote or local filesystem
to be mounted.

Used in mapfile generation. Example: 'data -rw nfs.example.org:/data/big'

Default: []


Limitations
------------

#### Removals
Directly calling the `autofs::package` and `autofs::service` classes is disabled in 3.0.0.
These are now private classes.

#### Puppet platforms
Compatible with Puppet 4 only. Puppet 4.6.0 will provide best results.

#### Operating Systems

* Supported
    * Ubuntu
      * 14.04
      * 16.04
    * CentOS/RHEL/Scientific/Oracle Linux
      * 6.x
      * 7.x
    * SLES
      * 11 Service Pack 4
      * 12 Service Pack 1
    * OpenSUSE 13.1
    * Debian
      * 7 "Wheezy"
      * 8 "Jessie"
* Self Support - should work, support not provided by developer
    * Solaris 10, 11
    * AIX 7.1, 7.2
    * Fedora 24, 25
    * SLES 10
    * CentOS/RHEL/Scientific/Oracle Linux 5.x
* Unsupported
    * Windows (Autofs not available)
    * Mac OS X

Development
-------------

Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for instructions regarding development environments and testing.

Authors
-------

* Vox Pupuli: [voxpupuli@groups.io](mailto:voxpupuli@groups.io)
* David Hollinger: [david.hollinger@moduletux.com](mailto:david.hollinger@moduletux.com)
