# Class: autofs::service
#
# The autofs::service class configures the autofs service.
# This class can be used to disable or limit the autofs service
# if necessary. Such as allowing the service to run, but not at
# startup.
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see autofs
# @see https://www.github.com/voxpupuli/autofs-puppet Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
#
# @author David Hollinger III <david.hollinger@moduletux.com>
#
# @param ensure Determines state of the service. Can be set to: running or stopped.
# @param enable Determines if the service should start with the system boot. true
#   will start the autofs service on boot. false will not start the autofs service
#   on boot.
# @param service_restart Determines if the service has a restart command. If true,
#   puppet will use the restart command to restart the service. If false, the
#   stop, then start commands will be used instead.
# @param service_status Determines if service has a status command.
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
