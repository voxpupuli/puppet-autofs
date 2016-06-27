# = Class: autofs::service
#
class autofs::service {
  service { 'autofs':
    ensure     => $autofs::service_ensure,
    enable     => $autofs::service_enable,
    hasstatus  => true,
    hasrestart => true,
  }
}
