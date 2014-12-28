# = Class: autofs::install
#
# This class ensures that autofs is installed.
#
class autofs::install {
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
    default: {
      fail("${::operatingsystem} not supported.")
    }
  }
}
