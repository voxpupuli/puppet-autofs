# @summary Defined type to manage overall autofs map files
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
# @param owner What owner for the mapfile (defaults to $autofs::map_file_owner)
# @param group What group for the mapfile (defaults to $autofs::map_file_group)
# @param mode What mode for the mapfile (defaults to $autofs::map_file_mode)
#     this is primarily useful for adding executable bits or setting restrictive
#     permissions.
#
# When autofs::manage_auto_master is true, autofs::master owns the Concat
# resource for the master map, and only one resource per path may exist in the
# catalog.  A mapfile whose path is that same file therefore contributes only
# its mappings as concat fragments and reuses the existing Concat.  Parameters
# that autofs::master does not honor (ensure, replace, owner, group, and mode)
# are silently ignored in that situation.  Prefer
# autofs::add_master_entry for master map entries.
#
define autofs::mapfile (
  Enum['present', 'absent'] $ensure   = 'present',
  Stdlib::Absolutepath $path          = $title,
  Array[Autofs::Fs_mapping] $mappings = [],
  Boolean $replace                    = true,
  String $owner                       = $autofs::map_file_owner,
  String $group                       = $autofs::map_file_group,
  String $mode                        = $autofs::map_file_mode,
) {
  unless $autofs::package_ensure == 'absent' {
    if $autofs::reload_command {
      $concat_notify = Exec['automount-reload']
    } else {
      $concat_notify = Service[$autofs::service_name]
    }
  } else {
    $concat_notify = undef
  }

  # autofs::master owns the Concat resource for the managed master map.
  # Declaring it here too would be a duplicate, so only declare our own Concat
  # when the path is a different file, or when the master map itself is not
  # managed (in which case autofs::master is not part of the catalog).
  if $path != $autofs::auto_master_map or !$autofs::manage_auto_master {
    ensure_resource('concat', $path,
      {
        ensure         => $ensure,
        owner          => $owner,
        group          => $group,
        mode           => $mode,
        ensure_newline => true,
        replace        => $replace,
        warn           => epp('autofs/mapfile.banner.epp', { 'replace' => $replace }),
        notify         => $concat_notify,
        require        => Class['autofs::package'],
      }
    )
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
