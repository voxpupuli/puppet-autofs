# @summary Defined type to add entries to the Autofs master map.
#
# Use this defined type to add entries to `/etc/auto.master` without having
# to declare a mount point. This is useful when:
#
# * A package drops files into a drop-in directory that you don't manage
# * You need entries other than `+dir:` (e.g., `+auto.master` for NIS)
# * You want a clean separation between master map entry management and mount
#   point management
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see https://voxpupuli.org/puppet-autofs/puppet_classes/autofs.html puppet_classes::autofs
# @see https://www.github.com/voxpupuli/puppet-autofs Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
#
# @author Vox Pupuli <voxpupuli@groups.io>
#
# @example Add a +dir: entry for drop-in files in a subdirectory
#   autofs::add_master_entry { 'myapp':
#     entry => '+dir:/etc/auto.master.d/myapp',
#   }
#
# @example Add a +dir: entry ensuring the directory exists
#   autofs::add_master_entry { 'myapp':
#     entry        => '+dir:/etc/auto.master.d/myapp',
#     ensure_dir   => true,
#   }
#
# @example Use title as entry (simplifies +dir: entries)
#   autofs::add_master_entry { '+dir:/etc/auto.master.d/myapp': }
#
# @example Add an arbitrary master map entry (e.g., NIS map inclusion)
#   autofs::add_master_entry { 'nis_maps':
#     entry => '+auto.master',
#   }
#
# @param ensure Whether the entry should be present in the master map.
#   (default: 'present')
# @param entry The content of the master map entry. Defaults to the resource
#   title, making it simple to add +dir: entries by using the title as the
#   entry. (default: $title)
# @param master Full path, including filename, to the autofs master map.
#   Usually the correct master map will be chosen automatically, and you will
#   not need to specify this.
# @param order The relative order in which the entry will appear in the
#   master map. (default: 50)
# @param ensure_dir When the entry is a +dir: entry, also ensure the
#   referenced directory exists.  (default: false)
#
define autofs::add_master_entry (
  Enum['present', 'absent'] $ensure = 'present',
  String $entry                     = $title,
  Stdlib::Absolutepath $master      = $autofs::auto_master_map,
  Integer $order                    = 50,
  Boolean $ensure_dir               = false,
) {
  if !$autofs::manage_auto_master {
    fail("autofs::add_master_entry[${title}]: cannot manage master map entries when manage_auto_master is false")
  }

  if $ensure == 'present' {
    if $ensure_dir and stdlib::start_with($entry, '+dir:') {
      # Extract directory from +dir:entry format
      autofs::mapdir { $title:
        path => $entry[5, -1],
      }
      $fragment_require = Autofs::Mapdir[$title]
    } else {
      $fragment_require = undef
    }

    concat::fragment { "autofs::add_master_entry ${title}":
      target  => $master,
      content => "${entry}\n",
      order   => $order,
      require => $fragment_require,
    }
  }
}
