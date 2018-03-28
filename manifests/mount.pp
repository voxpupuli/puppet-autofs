# Define: autofs::mount
#
# Defined type to manage mountpoint mappings in the Autofs master map,
# and / or to manage the corresponding map files.
# Supplemental mapfile content can be provided by autofs::map resources.
#
# Warning: if at least one autofs::mount is declared with ensure => present
# and master_manage => true (their defaults) then the entire master map is
# managed.  In that case, only mount points declared present by autofs::mount
# resources with master_manage => true will be retained in the master map.
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see https://voxpupuli.org/puppet-autofs/puppet_classes/autofs.html puppet_classes::autofs
# @see https://www.github.com/voxpupuli/puppet-autofs Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
#
# @author Vox Pupuli <voxpupuli@groups.io>
# @author David Hollinger III <david.hollinger@moduletux.com>
#
# @example Using the autofs::mount defined type to set up automount for user home directories.
#   autofs::mount { 'home':
#     mount          => '/home',
#     mapfile        => '/etc/auto.home',
#     mapcontents    => ['* -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl server.example.com:/path/to/home/shares'],
#     options        => '--timeout=120',
#     order          => 01
#   }
#
# @example Using the autofs::mount defined type to create an enty for an existing auto.smb file.
#   autofs::mount { 'smb':
#     mount          => '/smb',
#     mapfile        => 'program:/etc/auto.smb',
#     mapfile_manage => false,
#     options        => '--timeout=120',
#   }
#
# @example Remove an entry from the master map
#   autofs::mount { '/smb':
#     ensure  => 'absent',
#     mapfile => 'program:/etc/auto.smb',
#   }
#
# @example Manage a map file, but not an entry in the master map
#   autofs::mount { '/mnt/example':
#     mapfile       => '/etc/auto.example',
#     master_manage => false,
#     mapcontents   => [
#       'fs1 -rw /server.example.com:/path/to/example/share'
#     ],
#   }
#
# @param ensure When managing an entry in the master map, whether that entry
#   entry should be present, and when managing a corresponding map file,
#   whether that file should be present (default: 'present').
# @param execute If true, the $mapfile will be an executable script;
#   otherwise it will be a normal file, which Autofs will expect to be in
#   its standard map file format.  Meaningful only when $mapfile_manage is
#   true, and has implications on the appropriate value of `mapcontents`.
#   (default: false).
# @param mapcontents A filesystem mapping or an array of them, each in Autofs
#   map file format (non-executable maps); alternatively, shell script code
#   implementing the map (executable maps only).
#   Example: ['* -user,rw,soft nfs.example.org:/path/to']
#   (default: [])
# @param map_dir Full path, including directory name, to the autofs master
#   map drop-in directory. Required only when $use_dir is set to true.
#   (default: '/etc/auto.master.d')
# @param mapfile Name of the Autofs map file that will associate subdirectories
#   of the mountpoint directory with specific filesystems (often, but not
#   always, remote ones) and the appropriate mount options.  Alternatively, can
#   name the built-in '-hosts' map.
# @param mapfile_manage A boolean indicating whether the file designated by
#   the $mapfile parameter should be managed, too, as opposed to managing
#   only an entry in the master map (default: true).
# @param master Full path, including filename, to the autofs master map.
#   (default: <machine-dependent>)
# @param master_manage Whether to manage (an entry in) the master map as
#   described by this resource.
# @param mount The Autofs mount point directory, or '/-' for a direct map.
#   For indirect maps, Autofs will mount filesystems in automatically-created
#   subdirectories of this directory (default: the title of this resource).
# @param options Options to be specified for this mount point in the Autofs
#   master map (default: '').
# @param order The order of this mount point mapping in the master map,
#   relative to other mount point mappings.  Meaningful only when $use_dir
#   is false.  (default: 10)
# @param replace Whether the existing map file should be managed if it already
#   exists (the entry in the master map is managed regardless).  Set to false
#   if you only want to avoid modifying the file when it already exists
#   (default: true).
# @param use_dir If true, autofs will manage details of this mount point via
#   a file in the drop-in directory specified by $map_dir, instead of by
#   writing them directly into the master map.  The master map will still be
#   ensured to contain an appropriate '+dir:' mapping for the directory,
#   but that can support multiple mount point mappings, and it may be present
#   by default.  (default: false)
# @param direct Deprecated.  Retained for backwards compatibility, but has no
#   effect.  Opt for a direct map via your choice of $mount parameter --
#   the value '/-' (of $mount) is meaningful to Autofs for that purpose.
#   (default: true)
#
define autofs::mount (
  Enum['present', 'absent'] $ensure       = 'present',
  Stdlib::Absolutepath $mount             = $title,
  Integer $order                          = 10,
  Optional[Variant[Stdlib::Absolutepath,Autofs::Mapentry]] $mapfile = undef,
  Optional[String] $options               = '',
  Stdlib::Absolutepath $master            = $autofs::auto_master_map,
  Boolean $master_manage                  = true,
  Stdlib::Absolutepath $map_dir           = '/etc/auto.master.d',
  Boolean $use_dir                        = false,
  Optional[Boolean] $direct               = undef,  # deprecated
  Boolean $execute                        = false,
  Boolean $mapfile_manage                 = true,
  Variant[Array, String] $mapcontents     = [],
  Boolean $replace                        = true
) {
  include '::autofs'

  if $mapfile.is_a(Autofs::Mapentry) and $mapfile_manage {
    fail("Parameter 'mapfile_manage' must be false for complicated 'mapfile' ${mapfile}")
  }

  if $execute =~ NotUndef {
    deprecation('autofs::mount::direct',
        'Resource parameter $::autofs::mount::direct is deprecated and has no effect')
  }

  if !($master_manage or $mapfile_manage) {
    warn("Autofs::Mount[${title}] does not manage anything")
  }

  if $mapfile {
    $contents = "${mount} ${mapfile} ${options}\n"
  } else {
    $contents = "${mount} ${options}\n"
  }

  unless $::autofs::package_ensure == 'absent' {
    if $autofs::reload_command {
      Concat {
        before => Service[$autofs::service_name],
        notify => Exec['automount-reload'],
      }
      File_line {
        before => Service[$autofs::service_name],
        notify => Exec['automount-reload'],
      }
    } else {
      Concat {
        notify => Service[$autofs::service_name],
      }
      File_line {
        notify => Service[$autofs::service_name],
      }
    }
  }

  if $master_manage {
    if !defined(Concat[$master]) {
      concat { $master:
        owner          => $autofs::map_file_owner,
        group          => $autofs::map_file_group,
        mode           => '0644',
        ensure_newline => true,
      }
    }

    if $use_dir == false {
      if $ensure == 'present' {
        concat::fragment { "autofs::fragment preamble ${mount} ${mapfile}":
          target  => $master,
          content => $contents,
          order   => $order,
        }
      } else {
        # If there is at least one autofs::mount resource with
        # ensure => 'present' then the following is superfluous -- the master
        # map will be rebuilt without any contribution from this resource.  But
        # in case there isn't any such autofs::mount, we need to affirmatively
        # remove this resource's corresponding line, if any, from the master map.
        file_line { "remove_contents_${mount}_${mapfile}":
          ensure            => 'absent',
          path              => $master,
          match             => "^${contents}",
          match_for_absence => true,
        }
      }
    } else {
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
        content => $contents,
        require => File[$map_dir],
      }
    }
  }

  if $mapfile and $mapfile_manage {
    concat { $mapfile:
      ensure  => $ensure,
      owner   => $autofs::map_file_owner,
      group   => $autofs::map_file_group,
      mode    => $execute ? { true => '0755', default => '0644' },
      replace => $replace,
      force   => true,
      warn    => template('autofs/map.banner.erb'),
      require => Class['autofs::package'],
    }

    autofs::map { $title:
      ensure      => $ensure,
      mapfile     => $mapfile,
      mapcontents => $mapcontents,
    }
  }
}
