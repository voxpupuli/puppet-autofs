# @api private
#
# @summary The autofs::master class configures the autofs master map.
#
# This class is private and cannot be called outside of the autofs module
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see autofs
# @see https://www.github.com/voxpupuli/puppet-autofs Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
#
# @author Vox Pupuli <voxpupuli@groups.io>
#
class autofs::master {
  assert_private('Master class is private, please use main class parameters.')

  if $autofs::reload_command {
    $concat_notify = Exec['automount-reload']
  } else {
    $concat_notify = Service[$autofs::service_name]
  }

  ensure_resource('concat', $autofs::auto_master_map,
    {
      ensure         => 'present',
      owner          => $autofs::map_file_owner,
      group          => $autofs::map_file_group,
      mode           => $autofs::map_file_mode,
      ensure_newline => true,
      replace        => true,
      warn           => template('autofs/mapfile.banner.erb'),
      notify         => $concat_notify,
      require        => Class['autofs::package'],
    }
  )
}
