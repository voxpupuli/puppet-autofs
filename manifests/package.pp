# Class: autofs::package
#
# The autofs::package class installs the autofs package.
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see autofs
# @see https://www.github.com/voxpupuli/puppet-autofs Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
#
# @author Vox Pupuli <voxpupuli@groups.io>
# @author David Hollinger III <david.hollinger@moduletux.com>
#
# This class will determine if the OS running is a supported Linux distribution
# and install the appropriate package. It will prevent failures on a system
# that is running Solaris, but will not install anything as it should be installed
# by default.
#
# If the code doesn't find a matching supported OS, then the Puppet run will fail
# with a "OS not supported" message.
#
class autofs::package {
  Package {
    ensure => installed,
  }
  case $::osfamily {
    'Debian', 'Ubuntu': {
      package { 'autofs': }
    }
    'RedHat', 'CentOS': {
      package { 'autofs': }
    }
    'Suse': {
      package { 'autofs': }
    }
    'Solaris': {
      # Solaris includes autofs
      # Block to prevent failures
    }
    default: {
      fail("${::operatingsystem} not supported.")
    }
  }
}
