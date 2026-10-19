# @summary Defined type to manage mount point definitions in the Autofs master
#   map.
#
# This defined type manages both the master map entry and the map file.
# Master map entries are created using `autofs::add_master_entry` for both
# direct entries and `+dir:` entries.
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
#   not need to specify this.  Ignored (aside from validation) when
#   autofs::manage_auto_master is false, since the master map is then
#   unmanaged by this module.
# @param map_dir Full path, including directory name, to the autofs master
#   map's drop-in directory.  Relevant only when $use_dir is true.  (default:
#   '/etc/auto.master.d').
# @param use_dir If true, autofs will manage this mount via a file in the
#   master map's drop-in directory instead of directly in the master map.
#   Unless autofs::manage_auto_master is false, the master map will still be
#   managed, however, to ensure at least that it enables the (correct) drop-in
#   directory.  When autofs::manage_auto_master is false, the owner of the
#   master map must ensure the +dir: entry (or rely on a build of autofs that
#   reads the drop-in directory implicitly), but the drop-in files themselves
#   are still managed here.  This parameter must be true whenever
#   autofs::manage_auto_master is false.
#   Multiple mounts using the same drop-in directory share one +dir: master
#   map entry and one directory File; the first-evaluated mount configures
#   them, so mounts sharing a directory should agree on ensure, order, and
#   ensure_dir.
# @param options Options to be specified for the autofs mount point within
#   the master map.
# @param order The relative order in which entries will appear in the master
#   map.
# @param ensure_dir Whether to ensure the drop-in directory ($map_dir) exists
#   before writing entries into it.  Applies whether or not
#   autofs::manage_auto_master is true; when it is false, this is the only
#   way the module will create the directory.  When false, the directory is
#   expected to exist already, e.g. shipped by the autofs package.
#   (default: false)
#
define autofs::mount (
  Variant[Stdlib::Absolutepath,Autofs::Mapentry] $mapfile,
  Enum['present', 'absent'] $ensure       = 'present',
  Stdlib::Absolutepath $mount             = $title,
  Integer $order                          = 1,
  Optional[String] $options               = undef,
  Stdlib::Absolutepath $master            = $autofs::auto_master_map,
  Stdlib::Absolutepath $map_dir           = $autofs::default_map_dir,
  Boolean $use_dir                        = false,
  Boolean $ensure_dir                     = false,
) {
  include 'autofs'

  if !$autofs::manage_auto_master and !$use_dir {
    $msg = "autofs::mount[${title}]: autofs::manage_auto_master is false; set use_dir => true to record the entry in ${map_dir}"
    fail($msg)
  }

  $entry_content = "${mount} ${mapfile} ${options}"

  if $use_dir == false {
    # Direct entry in master map
    autofs::add_master_entry { "autofs::mount ${title}":
      ensure  => $ensure,
      master  => $master,
      order   => $order,
      entry   => $entry_content,
      require => Class['autofs::package'],
    }
  } else {
    # $use_dir == true: the entry is recorded as a drop-in file.  The +dir:
    # master map line is managed via autofs::add_master_entry only when the
    # master map itself is managed; otherwise the owner of the master map is
    # responsible for enabling the drop-in directory (see
    # autofs::manage_auto_master).
    if $autofs::manage_auto_master {
      # All use_dir mounts share one drop-in directory, and the +dir: line is
      # a single master-map entry.  Like autofs::mapdir collapses the
      # directory itself, declare the entry once per directory: the first
      # evaluated mount configures it (ensure, order, ensure_dir) and later
      # mounts reuse it.  (ensure_resources/ensure_resource are native types
      # only, so guard with defined().)
      unless defined(Autofs::Add_master_entry[$map_dir]) {
        autofs::add_master_entry { $map_dir:
          ensure     => $ensure,
          entry      => "+dir:${map_dir}",
          master     => $master,
          ensure_dir => $ensure_dir,
          order      => $order,
          require    => Class['autofs::package'],
        }
      }
      $dropin_require = Autofs::Add_master_entry[$map_dir]
    } else {
      # No +dir: entry is managed here, but ensure_dir still means "make sure
      # the drop-in directory exists".
      if $ensure_dir {
        autofs::mapdir { "autofs::mount ${title}":
          path    => $map_dir,
          require => Class['autofs::package'],
        }
        $dropin_require = Autofs::Mapdir["autofs::mount ${title}"]
      } else {
        $dropin_require = undef
      }
    }

    file { "${map_dir}/${name}.autofs":
      ensure  => $ensure,
      owner   => $autofs::map_file_owner,
      group   => $autofs::map_file_group,
      mode    => $autofs::map_file_mode,
      content => "${entry_content}\n",
      require => $dropin_require,
    }
  }
}
