# = Class: autofs::service
#
# The autofs::service class configures the autofs service.
# This class can be used to disable or limit the autofs service
# if necessary. Such as allowing the service to run, but not at
# startup.
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
