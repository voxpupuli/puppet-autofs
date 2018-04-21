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

### Master Map

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

```
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

* [Lookup docs](https://docs.puppet.com/puppet/4.7/lookup_quick.html#puppet-lookup:-quick-reference-for-hiera-users) 
* [Hiera 5 docs](https://docs.puppet.com/puppet/5.1/hiera_merging.html) if using Puppet >= 4.9


#### Direct Map `/-` argument

The autofs module supports Autofs direct maps naturally.  For a direct map,
simply specify the `mount` parameter as `/-`, just as is used for the purpose
in the `auto.master` file.  When this option is exercised, Autofs requires
the keys in the corresponding map file to be absolute paths of mountpoint
directories; this module does *not* validate that constraint.

##### example

Define:
``` puppet
autofs::mount { 'foo':
  mount       => '/-',
  mapfile     => '/etc/auto.foo',
  options     => '--timeout=120',
}
```

Hiera:
``` yaml
autofs::mounts:
  foo:
    mount: '/-'
    mapfile: '/etc/auto.foo'
    options: '--timeout=120'
```

#### `+dir:` drop-in directories

The autofs module supports the use of Autofs's `+dir:` option (Autofs 5.0.5
or later) to record master map content in drop-in files in a specified
directory instead of directly int rhe master map.  When a `mount`'s `use_dir`
parameter is `true` (default is `false`), the corresponding master map entry
is created as a separate file in the appropriate directory instead of being
written directly into the master map.  The master map is still, however,
ensured to contain an appropriate `+dir:` entry designating the chosen
drop-in directory.

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

#### Removing mount points

Unwanted mount points can be ensured `absent` to force their removal.  This
will remove them from the master map even if the master map is not otherwise
managed (and in that specific case, without otherwise managing that file),
either directly in the file or in the drop-in directory (but not both).  If
at least one mount point is managed `present` in the master map then it may
also be sufficient to simply omit unwanted mount points.

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

### Map Files

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
      key: '*'
      options: 'rw,soft,intr'
      fs: 'server.example.com:/path/to/home/shares'
```

Whichever form is used, the resulting mapping in file `/etc/auto.home` is

```
*	-rw,soft,intr	server.example.com:/path/to/home/shares
```

#### Multiple mappings in the same file

Multiple mappings may be declared for the same map file, either in the same
`autofs::mapfile` resource (or an entry in the `$::autofs::mappings` class
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

```
dataA	-ro	remote.com:/exports/dataA
dataB	-rw,noexec	remote.com:/exports/dataB
```

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

A hash of options that describe Autofs mount points for which entries
should appear in the master map.  Each entry is equivalent to the title and
a hash of the parameters of one `autofs::mount` resource.

#### `mapfiles`

Optional.

Data type: Hash

A hash of options that describe Autofs map files that should be managed.
Each entry is equivalent to the title and a hash of the parameters of one
`autofs::mapfile` resource.

#### `package_name`

Data type: String or Array[String]

The name of the Autofs package(s).  System-appropriate values for a variety
of target environments are included with the module, so this parameter
does not usually need to be specified explicitly.

#### `package_ensure`

Data type: String

Determines the required state of the autofs package. Can be set to: `installed`, `absent`, `lastest`, or a specific
version string.

Default: 'installed'

#### `service_name`

Data type: String

The name of the Autofs service, as appropriate for use with the target
environment's tools.  System-appropriate values for a variety of
target environments are included with the module, so this parameter
does not usually need to be specified explicitly.

#### `service_ensure`

Data type: Enum['running', 'stopped']

Determines required state of the autofs service.

Default: 'running'

#### `service_enable`

Data type: Boolean

Determines whether the autofs service should start at system boot.

Default: `true`

#### `reload_command`

Optional.

Data type: String

If specified, a command to execute in the target environment to reload
Autofs configuration without restarting the service.

#### `auto_master_map`

Data type: String

The absolute path to the Autofs master map.  The standard paths used on
a variety of supported environments are included with the module, so this
parameter does not usually need to be specified explicitly.

#### `map_file_owner`

Data type: String

The system user who should own the master map and any managed map files.
May be expressed either as a name or as a uid (in string form).  The
module defaults to 'root' for most environments and provides alternative
defaults for supported target environments that ordinarily differ in this
regard, so it is rarely necessary to specify this parameter explicitly
unless a non-standard value is desired.

#### `map_file_group`

Data type: String

The system group to which the master map and any managed map files should
be assigned.  May be expressed either as a name or as a gid (in string
form).  The module defaults to 'root' for most environments and provides
alternative defaults for supported target environments that ordinarily
differ in this regard, so it is rarely necessary to specify this
parameter explicitly unless a non-standard value is desired.

### Defines

#### Public Defines

* `autofs::mount`: Describes an entry in the master map.
* `autofs::mapfile`: Describes a (sun-format) map file and, optionally, some or all of its contents.
* `autofs::mapping`: Describes one (sun-format) filesystem mapping in a specific map file.

### Parameters for autofs::mount

#### `ensure`

Data type: String

The desired state of the mount definition in the master map.  If set to
`absent`, the resulting master map will not contain a mountpoint definition
corresponding to this resource. Defaults to `present`.

#### `mount`

Data type: Stblib::Absolutepath

The Autofs mountpoint described by this resource.  When this parameter has the value `/-`, this resource describes a direct
mount, and the keys in the corresponding map file must be absolute paths to mountpoint directories.  Otherwise, this
resource describes an indirect map, and this parameter is a base path to the automounted directories
described by the corresponding map file.   Defaults to the `title` of this `autofs::mount`.

#### `mapfile`

Data type: Stdlib::Absolutepath or Autofs::MapEntry

This parameter designates the automount map serving this mount.  Autofs supports a variety of options
here, but most commonly this is either an absolute path to a map file or the special string `-hosts`.

#### `options`

Optional.

Data type: String

This parameter provides Autofs and/or mount options to be specified for this
mount point in the master map.

#### `order` 

Data type: Integer

This parameter specifies the relative order of this mount point in the master map.

Default: 1

#### `master`

Data type: Stdlib::Absolutepath

This parameter specifies the path to the master map.  It's system-dependent
default value is usually the right choice.

Default: (system-dependent)

#### `map_dir`

Data type: Stdlib::Absolutepath

This parameter specifies the path to the Autofs master map drop-in directory
in which this mount's definition should reside.  This may differ from mount
to mount. Applies only to autofs 5.0.5 or later, and only when the `use_dir`
parameter is set to `true`.

Default: '/etc/auto.master.d'

#### `use_dir`

Data type: Boolean

This parameter specifies whether to manage this mount point via its own file
in a drop-in directory, as opposed to recording it directly in the master
map.  Relevant only for autofs 5.0.5 or later.

Default: `false`

### Parameters for autofs::mapfile

#### `ensure`

Data type: String

This parameter specifies the target state of this map file, either `present` or `absent`.

Default: 'present'

#### `path`

Data type: Stdlib::Absolutepath

The absolute path to the map file managed by this resource. e.g '/etc/auto.data'.

Default: the `title` of this resource.

#### `mappings`

Data type: Array of Autofs::Fs_mapping

Each element corresponds to one (sun-format) mapping in the file, with a key,
usually some mount options, and a specification of the filesystem(s) to
mount.  The filesystem specification format is extremely loose, accommodating
not only the typical case of a single remote filesystem spec, but also the
wide variety of Autofs-recognized alternatives such as shared mounts,
multi-mounts, and replicated mounts.

Example:
```puppet
[
  { 'key' => 'dataA', 'options' => 'rw,noexec', 'fs' => 'remote.net:/exports/dataA' }
]
```

Default: []

#### `replace`

Data type: Boolean

This parameter specifies whether this map file's contents should be managed
in the event that the file already exists at the start of the Puppet run.
It affects not only mappings specified directly in this resource, but also
any that are specified for this map file via separate `autofs::mapping`
resources.

Default: `true`

### Parameters for autofs::mapping

#### `ensure`

Data type: String

This parameter specifies whether the mapping it describes should be
present in the target map file, provided that that map file is managed
via an `autofs::mapfile` resource or the equivalent data among the
parameters of class `autofs`.  Setting the value `absent` is
substantially equivalent to altogether omitting any declaration of this
resource.

Default: 'present'

#### `mapfile`

The absolute path to the target map file hosting this mapping.

#### `key`

Data type: String matching /\A\S+\z/

The autofs key for this mapping.

#### `fs`

Data type: String matching /\S/

The filesystem specification for this mapping.  The Sun map format
permits a number of alternatives beyond simple, single mappings, and
this module opts to allow wide latitude in filesystem specification
instead of trying to codify all the alternatives.

Simple example: 'remote.net:/exports/data'

#### `options`

Optional.

Data type: String matching /A\S+\z/, or an Array of such Strings

Autofs and mount options specific to this mapping.  If given as and array
then elements are joined with commas (,) to form a single option string.
Options _should not_ be prefixed with a hyphen (-) unless that is part of
the option itself.  Options whose names do begin with a hyphen must not
be first.

example: 'rw,noexec,nodev'

example: \[ 'rw', 'noexec', 'nodev' \]

#### `order`

Data type: Integer

The relative order of this mapping in the target map file.  Does not
ordinarily need to be specified, because the map file order will be stable
either way, and the order matters only if the map contains more than one
mapping for the same key.

Default: 10


Limitations
------------

#### Removals
Directly calling the `autofs::package` and `autofs::service` classes is disabled in 3.0.0.
These are now private classes.

The `autofs::map` defined type is no longer documented or supported, and it will be removed
from a future version.

The `direct`, `executable`, `mapcontents`, `mapfile_manage`, and `replace` parameters of
`autofs::mount` are removed in 5.0.0, the first having already been ineffective in 4.3.0,
and the others no longer being relevant starting in 5.0.0.

#### Puppet platforms
Compatible with Puppet 4 or greater only. Puppet 4.6.0 or greater
(including Puppet 5) will provide best results.

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
