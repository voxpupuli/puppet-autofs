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
directory instead of directly in the master map.  When a `mount`'s `use_dir`
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

By default, map files are marked as `0644`. If a map file must be executable,
you can set the `execute` parameter to enforce `0755`.

```puppet
autofs::mapfile { 'home':
  path    => '/etc/auto.data',
  execute => true
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

The `autofs::map` defined type is no longer documented or supported, and it will be removed
from a future version.

The `direct`, `executable`, `mapcontents`, `mapfile_manage`, and `replace` parameters of
`autofs::mount` are removed in 5.0.0, the first having already been ineffective in 4.3.0,
and the others no longer being relevant starting in 5.0.0.

### Puppet platforms

Compatible with Puppet 4 or greater only. Puppet 4.6.0 or greater
(including Puppet 5) will provide best results.

### Operating Systems

For an up2date list of supported operating systems, take a look at the metadata.json.

## Development

Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for instructions regarding development environments and testing.

## Authors

* Vox Pupuli: [voxpupuli@groups.io](mailto:voxpupuli@groups.io)
* David Hollinger: [david.hollinger@moduletux.com](mailto:david.hollinger@moduletux.com)
