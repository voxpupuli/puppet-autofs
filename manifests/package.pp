# = Class: autofs::install
#
# This class ensures that autofs is installed.
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
