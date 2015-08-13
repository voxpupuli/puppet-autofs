Autofs Puppet Module
====================

[![Build Status](https://travis-ci.org/dhollinger/autofs-puppet.svg?branch=master)](https://travis-ci.org/dhollinger/autofs-puppet)
[![Puppet Forge](https://img.shields.io/puppetforge/v/dhollinger/autofs.svg)](https://forge.puppetlabs.com/dhollinger/autofs)

#### Table of Contents
1. [Description](#description)
2. [Setup](#setup)
  * [The module manages the following](#the-module-manages-the-following)
  * [Requirements](#requirements)
  * [Incompatibilities](#incompatibilities)
3. [Usage](#usage)
4. [Contact](#contact)

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

### Incompatibilities

* Does NOT work with Solaris Autofs
* Does NOT work with Windows or Mac OS X

### Usage

The module includes a single class:

```puppet
include autofs
```

By default this installs and starts the autofs service with the default master
file. No parameters exist yet, but are in active development to allow for more
granular control.

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

Currently, the defined type requires all parameters to build the autofs config,
however, support for more granular control is in active development.

In hiera, there's a `autofs::mounts` class you can configure, for example:
```yaml
---
autofs::mounts:
  home:
    mount: '/home'
    mapfile: '/etc/auto.home'
    mapcontents:
      - '* -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl server.example.com:/path/to/home/shares'
    options: '--timeout=120'
    order: 01
```

#### Parameters
* **mount_name** - This is a logical, descriptive name for what what autofs will be
mounting. This is represented by the "home:" and "tmp:" entries above.
* **mount** - This Mapping describes where autofs will be mounting to. This map
entry is referenced by concat as part of the generation of the /etc/auto.master
file.
* **mapfile** - This Mapping describes the name and path of the autofs map file.
This mapping is used in the auto.master generation, as well as generating the map
file from the auto.map.erb template.
* **mapcontent** - This Mapping describes the folders that will be mounted, the
mount options, and the path to the remote or local share to be mounted. Used in
mapfile generation.
* **options** - This Mapping describes the auto.master options to use (if any)
when mounting the automounts.
* **order** - This Mapping describes where in the auto.master file the entry will
be placed. Order CANNOT be duplicated.

Contact
-------

David Hollinger: [david.hollinger@moduletux.com](mailto:david.hollinger@moduletux.com)
