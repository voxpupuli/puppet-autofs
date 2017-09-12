# @api private
# Class: autofs::service
#
# The autofs::service class configures the autofs service.
# This class can be used to disable or limit the autofs service
# if necessary. Such as allowing the service to run, but not at
# startup.
#
# This class is private and cannot be called outside of the autofs module
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see autofs
# @see https://www.github.com/voxpupuli/puppet-autofs Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
#
# @author Vox Pupuli <voxpupuli@groups.io>
# @author David Hollinger III <david.hollinger@moduletux.com>
#
class autofs::service {
  assert_private('Service class is private, please use main class parameters.')
  service { 'autofs':
    ensure     => $autofs::service_ensure,
    enable     => $autofs::service_enable,
    hasstatus  => true,
    hasrestart => true,
    require    => Class['autofs::package'],
  }
}
