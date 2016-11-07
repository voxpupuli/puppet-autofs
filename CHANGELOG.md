## Release 1.4.4
### summary
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
