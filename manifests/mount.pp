# Define: autofs::mount
#
# Defined type to generate autofs mount point
# configuration files.
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see https://voxpupuli.org/puppet-autofs/puppet_classes/autofs.html puppet_classes::autofs
# @see https://www.github.com/voxpupuli/puppet-autofs Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
#
# @author Vox Pupuli <voxpupuli@groups.io>
# @author David Hollinger III <david.hollinger@moduletux.com>
#
# @example Using the autofs::mount defined type to setup automount for user home directories.
#   autofs::mount { 'home':
#     mount          => '/home',
#     mapfile        => '/etc/auto.home',
#     mapcontents    => ['* -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl server.example.com:/path/to/home/shares'],
#     options        => '--timeout=120',
#     order          => 01
#   }
#
# @example Using autofs::mount defined type to create an enty for an existing auto.smb file.
#   autofs::mount { 'smb':
#     mount          => '/smb',
#     mapfile        => 'program:/etc/auto.smb',
#     mapfile_manage => false,
#     options        => '--timeout=120',
#   }
#
# @example Remove an autofs::mount
#   autofs::mount { '/smb':
#     ensure  => 'absent',
#     mapfile => 'program:/etc/auto.smb',
#   }
#
# @param ensure Whether the mount should exist or not.
# @param mount Location where you will mount the remote NFS Share.
# @param mapfile Name of the "auto." configuration file that will be generated.
#   can be a filepath or maptype and path.
# @param mapcontents The mount point options and parameters.
#   Example: '* -user,rw,soft server.example.com:/path/to/home/shares'
# @param master Full path, including filename, to the autofs master file.
# @param map_dir Full path, including directory name, to the autofs master
#   configuration directory. Only required if use_dir is set to true.
# @param use_dir If true, autofs will look for master configuration in the map_dir
#   path using filenames ending in the ".autofs" extension.
# @param options Options for the autofs mount point within in the auto.master.
# @param order Order in which entries will appear in the autofs master file.
# @param direct Boolean to allow for indirect map. Defaults to true to be
#   backwards compatible.
# @param execute If true, it will make the $mapfile an executable script,
#   otherwise the file is a standard "auto." configuration file.
# @param mapfile_manage Boolean will manaage the map file specifed in mapfile
#   paramter.
# @param replace Set to false if you only want to place the file if it is missing.
#
define autofs::mount (
  Enum['present', 'absent'] $ensure       = 'present',
  Stdlib::Absolutepath $mount             = $title,
  Integer $order                          = 1,
  Optional[Variant[Stdlib::Absolutepath,Autofs::Mapentry]] $mapfile = undef,
  Optional[String] $options               = '',
  Stdlib::Absolutepath $master            = $autofs::auto_master_map,
  Stdlib::Absolutepath $map_dir           = '/etc/auto.master.d',
  Boolean $use_dir                        = false,
  Boolean $direct                         = true,
  Boolean $execute                        = false,
  Boolean $mapfile_manage                 = true,
  Variant[Array, String] $mapcontents     = [],
  Boolean $replace                        = true
) {
  include '::autofs'

  if $mapfile.is_a(Autofs::Mapentry) and $mapfile_manage {
    fail("Parameter 'mapfile_manage' must be false for complicated 'mapfile' ${mapfile}")
  }

  if $mapfile {
    $contents = "${mount} ${mapfile} ${options}\n"
  } else {
    $contents = "${mount} ${options}\n"
  }

  if $execute {
    $mapperms = '0755'
    $maptempl = 'autofs/auto.map.exec.erb'
  }
  else {
    $mapperms = '0644'
    $maptempl = 'autofs/auto.map.erb'
  }

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

  if $use_dir == false {
    if $ensure == 'present' {
      concat::fragment { "autofs::fragment preamble ${mount} ${mapfile}":
        target  => $master,
        content => $contents,
        order   => $order,
      }
    } else {
      file_line { "remove_contents_${mount}_${mapfile}":
        ensure            => absent,
        path              => $master,
        match             => "^${contents}",
        match_for_absence => true,
        notify            => Service['autofs'],
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
      mode    => $mapperms,
      content => $contents,
      require => File[$map_dir],
    }
  }

  if $mapfile and $mapfile_manage {
    autofs::map { $title:
      ensure      => $ensure,
      mapfile     => $mapfile,
      mapcontents => $mapcontents,
      replace     => $replace,
      template    => $maptempl,
      mapmode     => $mapperms,
    }
  }
}
