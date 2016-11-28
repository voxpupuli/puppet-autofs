# Class: autofs
#
# Manages autofs mount points
#
# This class includes defined types for looping through arrays of configuration
# file names.
#
# @see https://dhollinger.github.io/autofs-puppet home
# @see https://www.github.com/dhollinger/autofs-puppet Project Page
# @see https://forge.puppet.com/dhollinger/autofs Forge Page
#
# @author David Hollinger III <david.hollinger@moduletux.com>
#
# @example Declaring the autofs class
#    include autofs
#
# @param mounts hash parameter containing autofs config data
# @param use_map_dir boolean parameter determining the use of auto.master.d
# @param map_dir string parameter used to set the directory for use_map_dir
#
class autofs (
  Hash $mounts         = {},
  Boolean $use_map_dir = false,
  String $map_dir      = '/etc/auto.master.d'
) {
  class { 'autofs::package': }
  class { 'autofs::service': }
  contain 'autofs::package'
  contain 'autofs::service'

  if ( $mounts != {} ) {
    class { 'autofs::mounts': }
  }
}
