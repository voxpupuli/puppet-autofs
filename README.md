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

### Master Map

The module provides two compatible, built-in mechanisms for managing the
content of the master map: by setting the `mounts` parameter of the `autofs`
class, and by declaration of `autofs::mount` resources.  Using these is not
obligatory -- one could instead use a `File` resource, for instance, but
using the built-in mechanisms automatically provides for the autofs service
to be notified of any changes to the master map.

Note well, however, that managing the master map via this module's built-in
mechanisms is generally an all-or-nothing affair.  If any autofs mount points
are managed present in the master map via either of those mechanisms, then
*only* such mount points will appear in the master map.

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


#### Direct Map `/-` arugment

The autofs module supports Autofs direct maps naturally.  For a direct map, simply specify the `mount` parameter as `/-`,
just as is used for the purpose in the `auto.master` file.  When this option is exercised, Autofs requires the keys in the
corresponding map file to be absolute paths of mountpoint directories; this module does *not* validate that constraint.

##### Examples:

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

#### Autofs `+dir:` options

The autofs module supports the use of Autofs's `+dir:` option (Autofs 5.0.5 or later) in the `auto.master` file to
incorporate the contents of all files from a specified directory into the master map's own logical content.  When a
`mount`'s `use_dir` parameter is `true` (default is `false`), the corresponding `auto.master` content is created as a
separate file in the appropriate directory instead of being written directly into `auto.master`.  `auto.master` is,
however, ensured to contain an appropriate `+dir:` entry designating the chosen fragment directory.

##### Usage

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

### Map Files

This module provides several ways to manage Autofs map files, but it all starts with the
`autofs::mount` resource discussed above.  By default, such resources or their
corresponding external-data representations set up management for the designated map
file, as well, and they may provide some or all of the map file content. For example, this
Puppet code

```puppet
autofs::mount { 'home':
  mount       => '/home',
  mapfile     => '/etc/auto.home',
  mapcontents => ['* -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl server.example.com:/path/to/home/shares'],
  options     => '--timeout=120',
  order       => 01
}
```

not only manages an entry in the master map, as described above, but also ensures that the
designated map file exists and contains the mapping designated via the `mapcontents`
parameter:

#### /etc/auto.home
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

It is assumed in this case that the map file itself is managed separately, via an `autofs::mount` resource.

```puppet
autofs::mount{'auto.data':
  mapfile => '/etc/auto.data',
  mount   => '/big',
}
```

Multiple `autofs::map` resources may target the same map file.  The contents
they specify will be combined, together with any contents specified by the
overall `autofs::mount`.

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

Alternatively, to suppress all map file content declared via an `autofs::map`
resource, one can `ensure` the whole `autofs::map` as being `absent`:

```puppet
autofs::map {'data':
  ensure      => 'absent',
  mapfile     => '/etc/auto.data',
  mapcontents => [ 'dataA -o rw /mnt/dataA', 'dataB -o rw /mnt/dataB' ],
}
```

```yaml
autofs::maps:
  data:
    ensure: absent
    mapfile: '/etc/auto.data'
    mapcontents:
      - 'dataA -o rw /mnt/dataA'
      - 'dataB -o rw /mnt/dataB'
```

**NOTE:** this behavior of the `ensure` parameter is a change from that in
the original implementation of `autofs::map`, which would cause the whole
target map file to be removed (when it worked).  Before relying on this
documentation, be sure you are using a version of the module to which
this documentation applies.

#### Removing whole map files

By default, `autofs::mount` resources manage map files at least by ensuring
that they are present on the system and have appropriate ownership and mode.
It is straightforward, however, to instead manage them to be absent.  This
is accomplished via the `ensure` parameter:

```puppet
autofs::mount { 'unwanted':
  mount   => '/mnt/oops',
  mapfile => '/etc/auto.unwanted',
  ensure  => 'absent'
}
```

external-data variation:

```yaml
autofs::mounts:
  unwanted:
    mount: '/mnt/oops'
    mapfile: '/etc/auto.unwanted'
    ensure: 'absent'
```

The example will ensure not only that the map file is absent from the
system, but also the corresponding entry is absent from the master map.  The
effect can be narrowed to just one or the other via the general mechanism
for adjusting the scope of `autofs::mount`, discussed next. 

### Controlling `autofs::mount` scope

We have seen that by default, autofs::mount` resources both manage an
entry in the master map and play a central role in managing the associated
map file.  It may, however, be desirable for such resources to manage just
one or the other.  For this purpose, the type provides boolean parameters
`$mapfile_manage` and `$master_manage` that control whether an instance
in fact does manage a mapfile or an entry in the master map, respectively.
Both default to `true`.

In most cases, these parameters can be assigned values independently of
each other and of the other parameters, but if an `autofs::mount` resource
specifies a mapfile other than via an absolute path, such as by designating
the built-in "-hosts" map, then that resource's `$mapfile_manage` *must* be
specified as `false`.  Instances with `$mapfile_manage` and `$master_manage`
both `false` are accepted, but will elicit a warning.

#### Managing _only_ a master map entry

For example, one might use this Puppet code to manage a mount point for
the `-hosts` map:

```puppet
autofs::mount { 'hosts':
  mount          => '/net',
  mapfile        => '-hosts',
  mapfile_manage => false,
}
```

The equivalent external data is

```yaml
autofs::mounts:
  hosts:
    mount: '/net'
    mapfile: '-hosts'
    mapfile_manage: false
```

#### Managing _only_ a map file

On the other hand, suppose the target OS's autofs package enables a
drop-in directory automatically.  One can leverage that to set up autofs
mount points without modifying the master map (which indeed is one of the
purposes for the drop-in directory feature):

```puppet
autofs::mount { 'data':
  mount         => '/mnt/data',
  mapfile       => '/etc/auto.data',
  mapcontents   => ['dataA -ro remote.com:/exports/dataA']
  master_manage => false,
}

file { '/etc/auto.master.d/data.autofs':
  ensure  => 'file',
  user    => 'root',
  group   => 'root',
  mode    => '0644',
  content => '/mnt/data /etc/auto.data'
}
```

This module makes no provision for managing the drop-in `data.autofs` file
in this case, neither via a declarable resource type nor via external data.
It is treated as part of the master map, and therefore is managed if and
only if the master map is managed.


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

#### `maps`

Optional.

Data type: Hash

A hash of options that describe filesystem mappings in various mapfiles under management.
Each entry is equivalent to the title and a hash of parameters of one `autofs::map` resource.

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

#### `package_source`

Optional.

Data type: String

Specifies the name of the package source, for those target systems that
need it (AIX).  The system-dependent default value is normally appropriate.

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
Autofs configuration without restarting the service.  This module provides
system-dependent default values for several systems that provide such a
feature, so it is usually unnecessary to specify this parameter explicitly.

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

* `autofs::mount`: Describes an entry in the master map, and, optionally, some of or all of the contents of the corresponding
  map file.
* `autofs::map`: Describes a map file and some or all of its contents.

### Parameters for autofs::mount

#### `ensure`

Data type: String

The desired state of the mountpoint definition in the master map and / or
map file managed by this resource.  If set to `absent` and `$master_manage`
is `true` (its default), the master map will not contain a mountpoint
definition corresponding to this resource.  If set to `absent` and
`$mapfile_manage` is `true` (its default), the map file designated by
this resource will be ensured absent.  Defaults to `present`.

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

This parameter is optional only for backwards compatibility.  It _should_ always be provided.  If omitted,
the options will be interpreted as the map file, instead, and if both are omitted then any resulting
master map entry will be malformed.

If `master_manage` is `true` (its default) then this parameter corresponds to content in the master map.
If `mapfile_manage` is `true` (its default) then the presence of this parameter also causes the
corresponding map file to be managed.

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

This mapping describes the autofs and mount options to associate with the
master map entry, if any, managed by this resource.

Default: ''

#### `order` 

Data type: Integer

When this resource manages an entry in the master map, this parameter
designates its position relative to other managed entries.  Autofs is
sensitive to master map order only insomuchas multiple entries can be
matched to the same request, so often it is unnecessary to manage
entry order.

Default: 10

#### `master`

Data type: Stdlib::Absolutepath

This parameter specifies the path to the Autofs master map, if any, in
which this resource will manage an entry.  The provided system-dependant
default is usually appropriate, so it is rarely necessary to specify
this parameter explicitly.

Default: (system-dependent)

#### `master_manage`

Data type: Boolean

Indicates whether this resource should manage the master map to include
(or omit) the mount point declaration described by this resource.  In the
event that the catalog contains any `autofs::mount` resources that are
ensured present, it is advisable that _all_ wanted entries that should be
present in the master map be managed via `autofs::mount` resources having
`master_manage` set to `true.

Default: `true`

#### `map_dir`

Data type: Stdlib::Absolutepath

This parameter specifies the path to the Autofs master map drop-in directory
in which this mount's definition should reside.  This may differ from mount
to mount. Applies only to autofs 5.0.5 or later, and only when the `use_dir`
and `master_manage` parameters are both set to `true`.

Default: '/etc/auto.master.d'

#### `use_dir`

Data type: Boolean

This parameter specifies whether to manage this mount point via its own file
in a drop-in directory, as opposed to recording it directly in the master
map.  Relevant only for autofs 5.0.5 or later.

Default: `false`

#### `direct`

Deprecated.

Data type: Boolean

Retained for backwards compatibility, but has no effect.

Default: `true`

#### `execute`

Data type: Boolean

Whether the mapfile, if any, managed by this resource should be have
an executable mode.

This option is probably not what you want.  For a master map entry refering
to an executable map, you should declare the `mapfile` parameter with a
`program:` prefix, which requires `mapfile_manage` to be `false`.  You could
then manage the specified map program via some other resource, such as a
`File`.  This parameter is irrelevant to that scenario.

Default: `false`

#### `replace`

Data type: Boolean

When this resource is managing a map file and that file already exists, this
parameter specifies whether its contents should be managed according to this
resource and any `autofs::map` resources targeting the same file.

Default: `true`

### Parameters for autofs::map

#### `ensure`

Data type: String

Whether the mapfile contents should be present in the target map file.
Unlike in some previous versions of this module, the overall presence
or absence of the `mapfile` is unaffected.  Specifying 'absent' has
substantially the same effect as omitting the resource altogether.

Default: 'present'

#### `mapfile`

Data type: Stdlib::Absolutepath

The autofs map file for which this resource specifies contents. e.g '/etc/auto.data'.

#### `mapcontents`

Data type: String or Array

Each string corresponds to one line of the map file.

For non-executable map files, such a line should describe one filesystem mapping, in automount format.  There
are three whitespace-delimited fields: an identifying "key", which automount combines with the base path for
this map to form the mount path; the mount options as a comma-delimited string; and the remote or local filesystem
to be mounted.

Example: 'data -rw nfs.example.org:/data/big'

Default: []

#### `order`

Data type: Integer

The relative order of the map file contents managed by this resource, with
respect to that managed by other resources.  Order matters only in the event
that the same key appears multiple times, so this parameter rarely needs to
be specified.

Default: 50


Limitations
------------

#### Removals
Directly calling the `autofs::package` and `autofs::service` classes is disabled in 3.0.0.
These are now private classes.

#### Puppet platforms
Compatible with Puppet 4 or higher only. Puppet 4.6.0 or later, including
Puppet 5, will provide best results.

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
