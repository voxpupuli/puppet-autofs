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
The Autofs module is a Puppet module for managing the configuration of automount
network file system. This is a global module designed to be used by any
organization. This module assumes the use of Hiera to set variables and serve up
configuration files.

Setup
-----
### The Module manages the following:
* Autofs package
* Autofs service
* Autofs Configuration File (/etc/auto.master)
* Autofs Map Files (i.e. /etc/auto.home)

### Requirements

* The [stdlib](https://forge.puppetlabs.com/puppetlabs/stdlib) Puppet Library
* The [concat](https://github.com/puppetlabs/puppetlabs-concat) Puppet Module

### Usage

The module includes a single class:

```puppet
include autofs
```

By default this installs and starts the autofs service with the module's default master
file. 

You can also manage the state of the autofs package or service.

By default the module will install the autofs package and start/enable the autofs service.
You can configure this by using the parameters defined in the main init class.

For example, to ensure the package is absent:
```puppet
class { 'autofs':
  package_ensure => 'absent',
}
```

To ensure that a service is disabled and not running:
```puppet
class { 'autofs':
  service_ensure => 'stopped',
  service_enable => false,
}
```


### Map Files

To setup the Autofs Map Files, there is a defined type that can be used:
```puppet
autofs::mount { 'home':
  mount       => '/home',
  mapfile     => '/etc/auto.home',
  mapcontents => ['* -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl server.example.com:/path/to/home/shares'],
  options     => '--timeout=120',
  order       => 01
}
```
This will generate content in both the auto.master file and a new auto.home map
file:

##### auto.master
```
/home /etc/auto.home --timeout=120
```

##### auto.home
```
* -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl server.example.com:/path/to/home/shares
```

The defined type requires all parameters, except direct and execute, to build the autofs config.
The direct and execute parameters allow for the creation of indirect mounts, see the Parameters section for more information on the defaults for direct and execute.

In hiera, there's a `autofs::mounts` class you can configure, for example:
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

If you need to merge the `autofs::mounts` key from multiple files or hiera lookups, be sure to add the `lookup_options`
key and set the merge behavior for `autofs::mounts` to `merge: hash`

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

The autofs module also supports the use of the built in autofs `/-` argument used with Direct Maps.

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

The autofs module now supports the use of the `+dir:` option in the auto.master.
This option is 100% functional, but does require some work to simplify it.

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
In addition to adding map entries via the `mapcontents` parameter to `autofs::mount the `autofs::map` type can also be used.

##### Usage

Define:
```puppet
autofs::map{'data':
  map => '/etc/auto.data',
  mapcontents => 'data -user,rw,soft server.example.com:/path/to/data,
}
```

Hiera:
```yaml
autofs::maps:
  data:
    map: '/etc/auto.data'
    mapcontent: 'data -user,rw server.example.com:/path/to/data'
```

It is assumed that the map file itself has already been defined with
and `autofs::mount` first.

```puppet
autofs::mount{'auto.data':
  mapfile => '/etc/auto.data',
  mount   => '/big',
}
```


## Reference

### Classes

#### Public Classes

* autofs: Main class. Contains or calls all other classes or defines.

#### Private Classes

* autofs::package: Handles autofs packages.
* autofs::service: Handles the service.

### Parameters

#### `mounts`

Optional.

Data type: Hash

A hash of options that will build the configuration. This hash is passed to the Defined type.
Each hash key is the equivalent to a parameter in the `autofs::mount` defined type.

Default: `undef`

#### `package_ensure`

Data type: String

Determines the state of the package. Can be set to: installed, absent, lastest, or a specific version string.

Default: 'installed'

#### `service_ensure`

Data type: Enum['running', 'stopped']

Determines state of the service.

Default: 'running'

#### `service_enable`

Data type: Boolean

Determines if the service should start with the system boot.

Default: `true`

### Defines

#### Public Defines

* autofs::mount: Builds the autofs configuration.
* autofs::map: Builds map entires for autofs configuration.

### Parameters for autofs::mount

#### `mount_name`

Data type: String

This is a logical, descriptive name for what what autofs will be
mounting. This is represented by the `home:` and `tmp:` entries above.

#### `mount`

Data type: Stblib::Absolutepath

This Mapping describes where autofs will be mounting to. This map
entry is referenced by concat as part of the generation of the /etc/auto.master
file. Defaults to the `title` of the `autofs::mount`

#### `mapfile`

Data type: Stdlib::Absolutepath or Autofs::MapEntry

This Mapping describes the name and path of the autofs map file.
This mapping is used in the auto.master generation, as well as generating the map
file from the auto.map.erb template. This parameter is no longer required.
When anything other than a simple file path is used `mapfile_manage` must be false.

#### `mapfile_manage`

Data type: Boolean

If true the the mapfile file will be created and maintained. Defaults
to true. Set this to false when the map file is maintained some other way,
e.g auto.smb from the autofs package.

#### `mapcontents`

Data type: Array

This Mapping describes the folders that will be mounted, the
mount options, and the path to the remote or local share to be mounted. Used in
mapfile generation.

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

Data type: Boolean

Enable or disable indirect maps.

Default: `true`

#### `execute`

Data type: Boolean

Set mapfile to be executable.

Default: `false`

#### `replace`

Data type: Boolean

Whether or not to replace the mapfile if it already exists.

Default: `true`

### Parameters for autofs::map

#### `mapfile`

Data type: Stdlib::Absolutepath

mapfile file to add entry to. e.g '/etc/auto.data'.

#### `mapcontent`

Data type: String

This Mapping describes a folder that will be mounted, the
mount options, and the path to the remote or local share to be mounted. Used in
mapfile generation. e.g. 'data -rw nfs.example.org:/data/big


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
    * Fedora 24, 25
    * SLES 10
    * CentOS/RHEL/Scientific/Oracle Linux 5.x
* Unsupported
    * Windows (Autofs not available)
    * Mac OS X (Autofs Not Available)

Development
-------------

Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for instructions regarding development environments and testing.

Authors
-------

* Vox Pupuli: [voxpupuli@groups.io](mailto:voxpupuli@groups.io)
* David Hollinger: [david.hollinger@moduletux.com](mailto:david.hollinger@moduletux.com)
