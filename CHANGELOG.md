# Changelog

All notable changes to this project will be documented in this file.
Each new release typically also includes the latest modulesync defaults.
These should not affect the functionality of the module.

## [v4.2.1](https://github.com/voxpupuli/puppet-autofs/tree/v4.2.1) (2018-02-28)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v4.2.0...v4.2.1)

**Implemented enhancements:**

- Allow the special map name  "-hosts" in Autofs::Mapentry [\#93](https://github.com/voxpupuli/puppet-autofs/issues/93)
- Add ability to remove mounts and maps. [\#95](https://github.com/voxpupuli/puppet-autofs/pull/95) ([dhollinger](https://github.com/dhollinger))
- Update code to allow for the special -hosts map [\#94](https://github.com/voxpupuli/puppet-autofs/pull/94) ([dhollinger](https://github.com/dhollinger))

**Fixed bugs:**

- No option to remove an already defined autofs::mount [\#91](https://github.com/voxpupuli/puppet-autofs/issues/91)

**Closed issues:**

- autofs mount  [\#92](https://github.com/voxpupuli/puppet-autofs/issues/92)

## [v4.2.0](https://github.com/voxpupuli/puppet-autofs/tree/v4.2.0) (2017-12-09)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v4.1.0...v4.2.0)

**Merged pull requests:**

- Release 4.2.0 [\#88](https://github.com/voxpupuli/puppet-autofs/pull/88) ([bastelfreak](https://github.com/bastelfreak))
- regenerate puppet-strings docs [\#87](https://github.com/voxpupuli/puppet-autofs/pull/87) ([bastelfreak](https://github.com/bastelfreak))
- Remove EOL operatingsystems [\#86](https://github.com/voxpupuli/puppet-autofs/pull/86) ([ekohl](https://github.com/ekohl))
- release 4.1.0 [\#83](https://github.com/voxpupuli/puppet-autofs/pull/83) ([bastelfreak](https://github.com/bastelfreak))

## [v4.1.0](https://github.com/voxpupuli/puppet-autofs/tree/v4.1.0) (2017-10-11)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v4.0.0...v4.1.0)

**Merged pull requests:**

- Several fixes related to failing modulesync tests/support puppet5 [\#82](https://github.com/voxpupuli/puppet-autofs/pull/82) ([dhollinger](https://github.com/dhollinger))
- Release 4.0.0 [\#79](https://github.com/voxpupuli/puppet-autofs/pull/79) ([dhollinger](https://github.com/dhollinger))

## [v4.0.0](https://github.com/voxpupuli/puppet-autofs/tree/v4.0.0) (2017-09-13)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v3.2.0...v4.0.0)

**Breaking changes:**

- BREAKING: refactor hiera data lookup [\#76](https://github.com/voxpupuli/puppet-autofs/pull/76) ([dhollinger](https://github.com/dhollinger))

**Implemented enhancements:**

-  Fix spec test for autofs\_version fact [\#80](https://github.com/voxpupuli/puppet-autofs/pull/80) ([wyardley](https://github.com/wyardley))

**Fixed bugs:**

- Solaris support with tests [\#78](https://github.com/voxpupuli/puppet-autofs/pull/78) ([Nekototori](https://github.com/Nekototori))

**Merged pull requests:**

- Release 3.2.0 [\#75](https://github.com/voxpupuli/puppet-autofs/pull/75) ([dhollinger](https://github.com/dhollinger))

## [v3.2.0](https://github.com/voxpupuli/puppet-autofs/tree/v3.2.0) (2017-07-02)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v3.1.0...v3.2.0)

**Implemented enhancements:**

- Add Puppet 5 compatibility [\#74](https://github.com/voxpupuli/puppet-autofs/pull/74) ([dhollinger](https://github.com/dhollinger))

**Closed issues:**

- Not compatible with Puppet 5 [\#73](https://github.com/voxpupuli/puppet-autofs/issues/73)

**Merged pull requests:**

- Release 3.1.0 [\#72](https://github.com/voxpupuli/puppet-autofs/pull/72) ([bastelfreak](https://github.com/bastelfreak))

## [v3.1.0](https://github.com/voxpupuli/puppet-autofs/tree/v3.1.0) (2017-06-24)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v3.0.2...v3.1.0)

**Implemented enhancements:**

- Support map types in auto.master [\#67](https://github.com/voxpupuli/puppet-autofs/pull/67) ([traylenator](https://github.com/traylenator))
- Let `autofs::mount` mount option default to title. [\#66](https://github.com/voxpupuli/puppet-autofs/pull/66) ([traylenator](https://github.com/traylenator))
- Specify default for order parameter on auto::mount [\#65](https://github.com/voxpupuli/puppet-autofs/pull/65) ([traylenator](https://github.com/traylenator))
- Multiple autofs::map instances per map. [\#62](https://github.com/voxpupuli/puppet-autofs/pull/62) ([traylenator](https://github.com/traylenator))
- New boolean mapfile\_manage to manage mapfile [\#58](https://github.com/voxpupuli/puppet-autofs/pull/58) ([traylenator](https://github.com/traylenator))
- Introduce new type autofs::map [\#57](https://github.com/voxpupuli/puppet-autofs/pull/57) ([traylenator](https://github.com/traylenator))

**Fixed bugs:**

- Confine autofs\_version fact to Linux kernel. [\#69](https://github.com/voxpupuli/puppet-autofs/pull/69) ([jgreen210](https://github.com/jgreen210))

**Closed issues:**

- autofs\_version fact throws exception on mac OS X [\#68](https://github.com/voxpupuli/puppet-autofs/issues/68)
- mapcontents or mapcontent [\#63](https://github.com/voxpupuli/puppet-autofs/issues/63)
- autofs::map has issues when order not set [\#59](https://github.com/voxpupuli/puppet-autofs/issues/59)

**Merged pull requests:**

- bump minimal stdlib version to 4.13.1 [\#71](https://github.com/voxpupuli/puppet-autofs/pull/71) ([bastelfreak](https://github.com/bastelfreak))
- bump minimal puppet version to 4.7.0 [\#70](https://github.com/voxpupuli/puppet-autofs/pull/70) ([bastelfreak](https://github.com/bastelfreak))
- Fixes \#63 autofs::map mapcontent parameter to  mapcontents [\#64](https://github.com/voxpupuli/puppet-autofs/pull/64) ([traylenator](https://github.com/traylenator))
- Update map and mount defined types to address \#59 [\#61](https://github.com/voxpupuli/puppet-autofs/pull/61) ([dhollinger](https://github.com/dhollinger))

## [v3.0.2](https://github.com/voxpupuli/puppet-autofs/tree/v3.0.2) (2017-05-11)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v3.0.1...v3.0.2)

**Implemented enhancements:**

- Fixtures file now uses upstream git repos [\#53](https://github.com/voxpupuli/puppet-autofs/pull/53) ([dhollinger](https://github.com/dhollinger))

**Fixed bugs:**

- Update the concat allowed version range to include 3.0.0 and 4.0.0 [\#54](https://github.com/voxpupuli/puppet-autofs/pull/54) ([dhollinger](https://github.com/dhollinger))

**Closed issues:**

- autofs module forces use of puppetlabs/concat 2.x [\#48](https://github.com/voxpupuli/puppet-autofs/issues/48)
- Incorrect puppet/stdlib dependency declaration [\#46](https://github.com/voxpupuli/puppet-autofs/issues/46)

**Merged pull requests:**

- Release 3.0.2 [\#55](https://github.com/voxpupuli/puppet-autofs/pull/55) ([dhollinger](https://github.com/dhollinger))
- Fix rubocop errors [\#52](https://github.com/voxpupuli/puppet-autofs/pull/52) ([dhollinger](https://github.com/dhollinger))
- modulesync 0.21.2 [\#51](https://github.com/voxpupuli/puppet-autofs/pull/51) ([dhollinger](https://github.com/dhollinger))
- Bump minimum required stdlib version to 4.13.0 [\#47](https://github.com/voxpupuli/puppet-autofs/pull/47) ([alexjfisher](https://github.com/alexjfisher))

## [v3.0.1](https://github.com/voxpupuli/puppet-autofs/tree/v3.0.1) (2017-04-10)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v3.0.0...v3.0.1)

**Fixed bugs:**

- With new Stdlib type Asolutepath empty string is not valid. [\#40](https://github.com/voxpupuli/puppet-autofs/pull/40) ([mterzo](https://github.com/mterzo))

**Closed issues:**

- puppet-autofs [\#39](https://github.com/voxpupuli/puppet-autofs/issues/39)

**Merged pull requests:**

- Release 3.0.1 [\#41](https://github.com/voxpupuli/puppet-autofs/pull/41) ([dhollinger](https://github.com/dhollinger))

## [v3.0.0](https://github.com/voxpupuli/puppet-autofs/tree/v3.0.0) (2017-04-06)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v2.1.1...v3.0.0)

**Breaking changes:**

- Clean up data types [\#36](https://github.com/voxpupuli/puppet-autofs/issues/36)
- Prepare for 3.0.0 release [\#38](https://github.com/voxpupuli/puppet-autofs/pull/38) ([dhollinger](https://github.com/dhollinger))
- BREAKING Update data types and docs [\#37](https://github.com/voxpupuli/puppet-autofs/pull/37) ([dhollinger](https://github.com/dhollinger))
- BREAKING Remove unused mounts class  [\#35](https://github.com/voxpupuli/puppet-autofs/pull/35) ([dhollinger](https://github.com/dhollinger))
- BREAKING Make package and service private [\#34](https://github.com/voxpupuli/puppet-autofs/pull/34) ([dhollinger](https://github.com/dhollinger))

**Implemented enhancements:**

- Autofs version fact [\#26](https://github.com/voxpupuli/puppet-autofs/issues/26)
- Make package and service classes private [\#24](https://github.com/voxpupuli/puppet-autofs/issues/24)
- Remove autofs::mounts class [\#22](https://github.com/voxpupuli/puppet-autofs/issues/22)
- Add parameters for managing the package and service state [\#21](https://github.com/voxpupuli/puppet-autofs/issues/21)

**Closed issues:**

- Point Forge to the Module Documentation site [\#25](https://github.com/voxpupuli/puppet-autofs/issues/25)

**Merged pull requests:**

- Add with\_all\_deps method to compile test [\#32](https://github.com/voxpupuli/puppet-autofs/pull/32) ([dhollinger](https://github.com/dhollinger))
- \[blacksmith\] Bump version to 2.1.2-rc0 [\#29](https://github.com/voxpupuli/puppet-autofs/pull/29) ([dhollinger](https://github.com/dhollinger))
- Fix CHANGELOG release tag name for v2.1.1 [\#27](https://github.com/voxpupuli/puppet-autofs/pull/27) ([dhollinger](https://github.com/dhollinger))
- Add new fact for tracking autofs version [\#33](https://github.com/voxpupuli/puppet-autofs/pull/33) ([dhollinger](https://github.com/dhollinger))
- Add parameters for configuring package and service [\#31](https://github.com/voxpupuli/puppet-autofs/pull/31) ([dhollinger](https://github.com/dhollinger))

## [v2.1.1](https://github.com/voxpupuli/puppet-autofs/tree/v2.1.1) (2017-03-10)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v2.1.0...v2.1.1)

**Fixed bugs:**

- Instructions for managing autofs service appear to be incorrect [\#19](https://github.com/voxpupuli/puppet-autofs/issues/19)

**Closed issues:**

- Migrate autofs module to Vox Pupuli [\#1](https://github.com/voxpupuli/puppet-autofs/issues/1)

**Merged pull requests:**

- Prepare for 2.1.1 release [\#23](https://github.com/voxpupuli/puppet-autofs/pull/23) ([dhollinger](https://github.com/dhollinger))
- Remove invalid documentation [\#20](https://github.com/voxpupuli/puppet-autofs/pull/20) ([dhollinger](https://github.com/dhollinger))
- update project information [\#17](https://github.com/voxpupuli/puppet-autofs/pull/17) ([benkevan](https://github.com/benkevan))
- General cleanup and corrections [\#15](https://github.com/voxpupuli/puppet-autofs/pull/15) ([dhollinger](https://github.com/dhollinger))

## [v2.1.0](https://github.com/voxpupuli/puppet-autofs/tree/v2.1.0) (2017-01-14)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v2.0.1...v2.1.0)

**Implemented enhancements:**

- Cleanup call to autofs::mount [\#9](https://github.com/voxpupuli/puppet-autofs/pull/9) ([dhollinger](https://github.com/dhollinger))

**Fixed bugs:**

- `mount` should not default to an empty array. [\#5](https://github.com/voxpupuli/puppet-autofs/issues/5)

**Merged pull requests:**

- Prepare for 2.1.0 release [\#12](https://github.com/voxpupuli/puppet-autofs/pull/12) ([dhollinger](https://github.com/dhollinger))
- Updates puppet-strings docs [\#10](https://github.com/voxpupuli/puppet-autofs/pull/10) ([dhollinger](https://github.com/dhollinger))
-  migrate beaker tasks to ruby240/trusty env [\#8](https://github.com/voxpupuli/puppet-autofs/pull/8) ([bastelfreak](https://github.com/bastelfreak))
- Update documentation [\#7](https://github.com/voxpupuli/puppet-autofs/pull/7) ([dhollinger](https://github.com/dhollinger))
- Prepare for 2.0.1 release [\#4](https://github.com/voxpupuli/puppet-autofs/pull/4) ([dhollinger](https://github.com/dhollinger))

## [v2.0.1](https://github.com/voxpupuli/puppet-autofs/tree/v2.0.1) (2017-01-06)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v2.0.0...v2.0.1)

**Merged pull requests:**

- Migration prep [\#3](https://github.com/voxpupuli/puppet-autofs/pull/3) ([dhollinger](https://github.com/dhollinger))

## [v2.0.0](https://github.com/voxpupuli/puppet-autofs/tree/v2.0.0) (2016-12-30)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.4.5...v2.0.0)

## [v1.4.5](https://github.com/voxpupuli/puppet-autofs/tree/v1.4.5) (2016-12-20)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.4.4...v1.4.5)

## [v1.4.4](https://github.com/voxpupuli/puppet-autofs/tree/v1.4.4) (2016-11-07)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.4.3...v1.4.4)

## [v1.4.3](https://github.com/voxpupuli/puppet-autofs/tree/v1.4.3) (2016-10-20)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.4.2...v1.4.3)

## [v1.4.2](https://github.com/voxpupuli/puppet-autofs/tree/v1.4.2) (2016-07-22)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.4.1...v1.4.2)

## [v1.4.1](https://github.com/voxpupuli/puppet-autofs/tree/v1.4.1) (2016-07-22)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.4.0...v1.4.1)

## [v1.4.0](https://github.com/voxpupuli/puppet-autofs/tree/v1.4.0) (2016-06-28)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.3.2...v1.4.0)

## [v1.3.2](https://github.com/voxpupuli/puppet-autofs/tree/v1.3.2) (2016-06-27)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.3.1...v1.3.2)

## [v1.3.1](https://github.com/voxpupuli/puppet-autofs/tree/v1.3.1) (2016-06-04)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.3.0...v1.3.1)

## [v1.3.0](https://github.com/voxpupuli/puppet-autofs/tree/v1.3.0) (2016-04-09)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.2.0...v1.3.0)

## [v1.2.0](https://github.com/voxpupuli/puppet-autofs/tree/v1.2.0) (2016-02-26)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.1.8...v1.2.0)

## [v1.1.8](https://github.com/voxpupuli/puppet-autofs/tree/v1.1.8) (2016-01-21)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.1.7...v1.1.8)

## [v1.1.7](https://github.com/voxpupuli/puppet-autofs/tree/v1.1.7) (2015-08-13)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.1.4...v1.1.7)

## [v1.1.4](https://github.com/voxpupuli/puppet-autofs/tree/v1.1.4) (2015-07-24)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.1.3...v1.1.4)

## [v1.1.3](https://github.com/voxpupuli/puppet-autofs/tree/v1.1.3) (2015-07-20)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.1.2...v1.1.3)

## [v1.1.2](https://github.com/voxpupuli/puppet-autofs/tree/v1.1.2) (2015-06-19)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.1.1...v1.1.2)

## [v1.1.1](https://github.com/voxpupuli/puppet-autofs/tree/v1.1.1) (2014-12-28)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.1.0...v1.1.1)

## [v1.1.0](https://github.com/voxpupuli/puppet-autofs/tree/v1.1.0) (2014-12-28)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.0.4...v1.1.0)

## [v1.0.4](https://github.com/voxpupuli/puppet-autofs/tree/v1.0.4) (2014-12-23)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.0.2...v1.0.4)

## [v1.0.2](https://github.com/voxpupuli/puppet-autofs/tree/v1.0.2) (2014-12-23)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.0.1...v1.0.2)

## [v1.0.1](https://github.com/voxpupuli/puppet-autofs/tree/v1.0.1) (2014-12-23)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v1.0.0...v1.0.1)

## [v1.0.0](https://github.com/voxpupuli/puppet-autofs/tree/v1.0.0) (2014-12-23)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v0.9.1...v1.0.0)

## [v0.9.1](https://github.com/voxpupuli/puppet-autofs/tree/v0.9.1) (2014-12-23)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v0.9.0...v0.9.1)

## [v0.9.0](https://github.com/voxpupuli/puppet-autofs/tree/v0.9.0) (2014-12-22)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v0.6.0...v0.9.0)

## [v0.6.0](https://github.com/voxpupuli/puppet-autofs/tree/v0.6.0) (2014-12-19)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v0.2.1...v0.6.0)

## [v0.2.1](https://github.com/voxpupuli/puppet-autofs/tree/v0.2.1) (2014-12-12)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v0.2.0...v0.2.1)

## [v0.2.0](https://github.com/voxpupuli/puppet-autofs/tree/v0.2.0) (2014-12-11)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/v0.1.0...v0.2.0)

## [v0.1.0](https://github.com/voxpupuli/puppet-autofs/tree/v0.1.0) (2014-08-29)

[Full Changelog](https://github.com/voxpupuli/puppet-autofs/compare/1f7f1808fa54469f37826dd095fbdb52c9f913c0...v0.1.0)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
