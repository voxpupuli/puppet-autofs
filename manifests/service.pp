# @api private
#
# @summary The autofs::service class configures the autofs service.
#
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

  if $autofs::manage_service_config {
    # Only manage the file if the path is set
    if $autofs::service_conf_path {
      file { 'autofs_service_config':
        ensure  => 'file',
        content => epp(
          'autofs/service_conf.epp',
          {
            service_conf_options    => $autofs::service_conf_options,
            service_options         => $autofs::service_options,
            service_use_misc_device => $autofs::service_use_misc_device,
          }
        ),
        group   => $autofs::map_file_group,
        mode    => '0644',
        notify  => Service[$autofs::service_name],
        owner   => $autofs::map_file_owner,
        path    => $autofs::service_conf_path,
      }
    }
  }

  if $autofs::manage_ldap_auth_conf {
    # Only manage the file if the path is set
    if $autofs::ldap_auth_conf_path {
      file { 'autofs_ldap_auth_config':
        ensure  => 'file',
        content => epp(
          'autofs/autofs_ldap_auth.conf.epp', {
            ldap_auth_config => $autofs::ldap_auth_config,
          }
        ),
        group   => $autofs::map_file_group,
        mode    => '0600',
        notify  => Service[$autofs::service_name],
        owner   => $autofs::map_file_owner,
        path    => $autofs::ldap_auth_conf_path,
      }
    }
  }

  service { $autofs::service_name:
    ensure     => $autofs::service_ensure,
    enable     => $autofs::service_enable,
    hasstatus  => true,
    hasrestart => true,
    require    => Class['autofs::package'],
  }

  if $autofs::reload_command {
    exec { 'automount-reload':
      path        => '/sbin:/usr/sbin',
      command     => $autofs::reload_command,
      refreshonly => true,
      require     => Service[$autofs::service_name],
    }
  }
}
