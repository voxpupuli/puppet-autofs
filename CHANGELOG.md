## Release 2.0.1
### Summary
This release migrates the module from dhollinger to VoxPupuli under the Puppet
namespace.

#### Changes
- Migrate to VoxPupuli
- Update README badges
- Update Puppet Strings urls
- Cleanup code to pass Rubocop and Puppet-Lint checks
- Improve the `autofs::mounts` tests

## Release 2.0.0
### Summary
This release removes unused parameters and adds Puppet 4.x Data Types to the module's
parameters. This release also adds Puppet Strings Documentation, adds support for
additional Operating Systems, and adds more acceptance tests for Validation.

#### Changes
- Remove Puppet 3.x Support as it is End of Life.
- (Issue #22) Add data types to the parameters.
  - Primary reason for major version change as this renders the module incompatible
    with Puppet 3.x
- (Issue #23) Add Puppet Strings Documentation.
- Remove unused parameters.
- Add additional acceptance tests.
- Add Travis Beaker nodesets for Debian 7 and Ubuntu 16.04
- Add support for the following Operating Systems:
  - Supported
    - Scientific Linux 6.x and 7.x
    - Oracle Enterprise Linux 6.x and 7.x
    - OpenSuSE 13.1
    - SuSE Linux Enterprise Server 11 SP4 and 12 SP1
  - Self Support
    - Fedora 24 and 25
    - CentOS/RHEL/Oracle Linux/Scientific Linux 5.x
    - SuSE Linux Enterprise Server 10
  - Removed Support
    - Fedora 20 and 21

## Release 1.4.5
### Summary
This release adds SLES support to the module and adds a deprecation warning that
Puppet 3.x support ends on Dec 31, 2016

#### Enhancements
- (Pull Request #25) Add SUSE package name. Thanks mattqm!
- Add Puppet 3.x End of Support deprecation warning to the README.

## Release 1.4.4
### Summary
This Release provides a minor improvement to how the module interacts with Hiera and is less strict with the upper bounds of the puppetlabs-stdlib module version requirement.

#### Enhancements
- (Pull Request #19) Now we can hash over Hieradata
- (Issue #21) Puppetlabs-stdlib version range is too restrictive
- Add CONTRIBUTING.md file for Contribution directions
- Add CONTRIBUTORS file to list those that have put in time to help make the module better
- Update and cleanup README file in small ways

## Release 1.4.3
### Summary
This Release fixes a bug where the autofs service would attempt to start before the package was installed.

#### Bugfixes
- (Issue #20) Service autofs requires package autofs

#### Enhancements
- Add Initial Acceptance Tests

## Release 1.4.2
### Summary
This is a Documentation update.

## Release 1.4.1
### Summary
This release adds a new feature that allows a map file to be deployed but not replaced.

#### Features
- (Feature #14) - Specify a mount point and map file that is deployed only once

#### Enhancements
- Add tests for the new replace feature

## Release 1.4.0
### Summary
This release fixes bugs related to .autofs config files in /etc/auto.master.d, removes depracated concat::fragment
attributes, and other general improvments.

#### Bugfixes
- (#15) - Fixes issue where a newline was not being added when +dir option was added to auto.master
- (#16) - Fix a Duplicate Declaration of File[/etc/auto.master.d]

#### Enhancements
- (#17) - Remove Deprecated ensure attribute from concat::fragment resources
- Up the puppetlabs/concat requirement to a minimum of 2.0.0

## Release 1.3.2
### Summary
This release no longer requires mapfile parameter to be set.

#### Features
- $mapfile is not longer required

## Release 1.3.1
### Summary
This release added support for the Autofs Configuration Directory, Direct Maps on multiple Mounts, and Experimental
Solaris support.

### Features
- (#7) Add support for Autofs Configuration Directory
- (#8) Add support for Direct Maps on multiple mounts
- (#9) Add Experimental Solaris Support

## Release 1.3.0
### Summary
Maintenance release
