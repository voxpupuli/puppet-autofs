# = Class: autofs::install
#
# This class ensures that autofs is installed.
#
class autofs::install {
  Package {
    ensure => installed
  }
  case $::osfamily {
    Debian: {
      package { 'autofs-ldap': }
    }
    RedHat: {
      package { 'autofs': }
    }
    Ubuntu: {
      package { 'autofs': }
    }
    default: {
      fail("${::operatingsystem} not supported.")
    }
  }
}
