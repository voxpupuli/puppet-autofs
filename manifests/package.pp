# = Class: autofs::package
#
# The autofs::package class installs the autofs package.
#
class autofs::package {
  Package {
    ensure => installed
  }
  case $::osfamily {
    'Debian', 'Ubuntu': {
      package { 'autofs': }
    }
    'RedHat', 'CentOS': {
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
