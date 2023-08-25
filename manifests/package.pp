# @api private
#
# @summary The autofs::package class installs the autofs package.
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see autofs
# @see https://www.github.com/voxpupuli/puppet-autofs Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
#
# @author Vox Pupuli <voxpupuli@groups.io>
# @author David Hollinger III <david.hollinger@moduletux.com>
#
# This is a private class and cannot be called outside of the autofs module.
#
class autofs::package {
  assert_private('Package class is private, please use main class parameters')

  if $autofs::package_name {
    package { $autofs::package_name:
      ensure => $autofs::package_ensure,
      source => $autofs::package_source,
    }
  }
}
