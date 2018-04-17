# Define: autofs::mount
#
# Defined type to manage mount point definitions in the Autofs master map.
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see https://voxpupuli.org/puppet-autofs/puppet_classes/autofs.html puppet_classes::autofs
# @see https://www.github.com/voxpupuli/puppet-autofs Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
#
# @author Vox Pupuli <voxpupuli@groups.io>
# @author David Hollinger III <david.hollinger@moduletux.com>
#
# @example Declaring an autofs mount point for automounting user home directories.  (The
#     corresponding map file needs to be managed separately.)
#   autofs::mount { 'home':
#     mount          => '/home',
#     mapfile        => '/etc/auto.home',
#     options        => '--timeout=120',
#   }
#
# @example Declaring a mount point with an executable map (to be managed
#     separately, if needed).
#   autofs::mount { 'smb':
#     mount          => '/smb',
#     mapfile        => 'program:/etc/auto.smb',
#     options        => '--timeout=120',
#   }
#
# @example Remove an entry from the master map (the map file is unaffected)
#   autofs::mount { '/smb':
#     ensure  => 'absent',
#     mapfile => 'program:/etc/auto.smb',
#   }
#
# @param ensure Whether a definition of this mount point should be present in the
#   master map.  (default: 'present')
# @param mount The absolute path of the Autofs mount point being managed.  For
#   a direct map, this should be '/-'.  Otherwise, it designates the parent
#   directory of the filesystem mount points managed by the map assigned to this
#   Autofs mount point.  (default: the title of this resource)
# @param mapfile a designation for the Autofs map associated with this mount
#   point.  Typically, this is an absolute path to a map file, whose base name
#   conventionally begins with "auto.", but Autofs recognizes other alternatives,
#   too, that can be specified via this parameter.
# @param master Full path, including filename, to the autofs master map.
#   Usually the correct master map will be chosen automatically, and you will
#   not need to specify this.
# @param map_dir Full path, including directory name, to the autofs master
#   map's drop-in directory.  Relevant only when $use_dir is true.  (default:
#   '/etc/auto.master.d').
# @param use_dir If true, autofs will manage this mount via a file in the
#   master map's drop-in directory instead of directly in the master map.
#   The master map will still be managed, however, to ensure at least that
#   it enables the (correct) drop-in directory.
# @param options Options to be specified for the autofs mount point within
#   the master map.
# @param order The relative order in which entries will appear in the master
#   map.  Irrelevant when $use_dir is true.
#
define autofs::mount (
  Variant[Stdlib::Absolutepath,Autofs::Mapentry] $mapfile,
  Enum['present', 'absent'] $ensure       = 'present',
  Stdlib::Absolutepath $mount             = $title,
  Integer $order                          = 1,
  Optional[String] $options               = undef,
  Stdlib::Absolutepath $master            = $autofs::auto_master_map,
  Stdlib::Absolutepath $map_dir           = '/etc/auto.master.d',
  Boolean $use_dir                        = false,
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

  if !defined(Concat[$master]) {
    concat { $master:
      owner          => $autofs::map_file_owner,
      group          => $autofs::map_file_group,
      mode           => '0644',
      ensure_newline => true,
    }
  }

  $contents = "${mount} ${mapfile} ${options}"

  if $use_dir == false {
    if $ensure == 'present' {
      concat::fragment { "autofs::fragment preamble ${mount} ${mapfile}":
        target  => $master,
        content => "${contents}\n",
        order   => $order,
      }
    } else {
      # If the master map is being managed via other autofs::mount resources,
      # too, at least one of which is ensured present, then this File_line is
      # unnecessary.  Otherwise, however, it is required for ensuring this
      # mount absent to be effective.
      file_line { "${master}::${mount}_${mapfile}":
        ensure            => 'absent',
        path              => $master,
        match             => "^\\s*${mount}\\s+${mapfile}\\s",
        match_for_absence => true,
        multiple          => true,
        notify            => Service['autofs'],
      }
    }
  } else {  # $use_dir == true
    ensure_resource('file', $map_dir, {
      'ensure'  => directory,
      'owner'   => $autofs::map_file_owner,
      'group'   => $autofs::map_file_group,
      'mode'    => '0755',
      'require' => Class['autofs::package'],
    })

    if !defined(Concat::Fragment['autofs::fragment preamble map directory']) and $ensure == 'present' {
      concat::fragment { 'autofs::fragment preamble map directory':
        target  => $master,
        content => "+dir:${map_dir}",
        order   => $order,
        require => File[$map_dir],
      }
    }

    file { "${map_dir}/${name}.autofs":
      ensure  => $ensure,
      owner   => $autofs::map_file_owner,
      group   => $autofs::map_file_group,
      mode    => '0644',
      content => "${contents}\n",
      require => File[$map_dir],
    }
  }
}
