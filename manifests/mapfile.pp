# Define autofs::mapfile
#
# Defined type to manage overall autofs map files
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see https://voxpupuli.org/puppet-autofs/puppet_classes/autofs.html puppet_classes::autofs
# @see https://www.github.com/voxpupuli/puppet-autofs Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
#
# @author Vox Pupuli <voxpupuli@groups.io>
# @author David Hollinger III <david.hollinger@moduletux.com>
#
# @param ensure Whether the mapfile should be present on the target system
# @param path An absolute path to the map file
# @param mappings an array of mappings to enroll in the file.  Additional
#     mappings can be specified for this mapfile via autofs::mapping resources
# @param replace Whether to replace the contents of any an existing file
#     at the specified path
#
define autofs::mapfile (
  Enum['present', 'absent'] $ensure   = 'present',
  Stdlib::Absolutepath $path          = $title,
  Array[Autofs::Fs_mapping] $mappings = [],
  Boolean $replace                    = true,
) {
  include '::autofs'

  unless $::autofs::package_ensure == 'absent' {
    if $autofs::reload_command {
      Concat {
        before => Service[$autofs::service_name],
        notify => Exec['automount-reload'],
      }
    } else {
      Concat {
        notify => Service[$autofs::service_name],
      }
    }
  }

  concat { $path:
    ensure  => $ensure,
    owner   => $autofs::map_file_owner,
    group   => $autofs::map_file_group,
    mode    => '0644',
    replace => $replace,
    require => Class['autofs::package'],
    warn    => template('autofs/mapfile.banner.erb'),
  }

  if $ensure == 'present' {
    $mappings.each |$mapping| {
      autofs::mapping { "${path}:${mapping[key]}":
        ensure  => 'present',
        mapfile => $path,
        *       => $mapping,
      }
    }
  }
}
