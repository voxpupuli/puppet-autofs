# = Class: autofs::service
#
class autofs::service (
  String $ensure           = running,
  Boolean $enable          = true,
  Boolean $service_restart = true,
  Boolean $service_status  = true
){
  service { 'autofs':
    ensure     => $ensure,
    enable     => $enable,
    hasstatus  => $service_status,
    hasrestart => $service_restart,
    require    => Package['autofs'],
  }
}
