# = Class: autofs::service
#
class autofs::service (
  $ensure = running,
  $enable = true,
  $service_restart = true,
  $service_status = true
){
  service { 'autofs' :
  ensure     => $ensure,
  enable     => $enable,
  hasstatus  => $service_status,
  hasrestart => $service_restart,
  }
}
