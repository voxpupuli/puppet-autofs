# Class: autofs
#
# Manages autofs mount points
#
# This class includes defined types for looping through arrays of configuration
# file names.
#
# @see https://dhollinger.github.io/autofs-puppet Home
# @see https://www.github.com/dhollinger/autofs-puppet Github
# @see https://forge.puppet.com/dhollinger/autofs Puppet Forge
#
# @author David Hollinger III <david.hollinger@moduletux.com>
#
# @example Declaring the autofs class
#    include autofs
#
# @param mounts the options to build the autofs config from
# @option mounts [String] :mount Location autofs will mount the share
# @option mounts [Integer] :order Order in which the config will be placed
#   in auto.master
# @option mounts [String] :options Mount options
# @option mounts [String] :master Full path to the autofs master file,
#   including filename
# @option mounts [String] :map_dir Full path to the master configuration
#   directory. Only used with :use_dir
# @option mounts [Boolean] :use_dir Use the +dir option or not.
# @option mounts [Boolean] :direct Use direct mounts or not.
# @option mounts [Boolean] :execute Make the auto.* file executable or not.
# @option mounts [String] :mapfile Name of the "auto.*" configuration file to
#   be generated.
# @option mounts [Array] :mapcontents Mount point options and parameters. Each
#   array element represents a line in the configuration file.
# @option mounts [Boolean] :replace Enforce the configuration state or not.
# @param use_map_dir boolean parameter determining the use of auto.master.d
# @param map_dir string parameter used to set the directory for use_map_dir
#
class autofs (
  Hash $mounts         = {}
) {
  contain '::autofs::package'
  contain '::autofs::service'

  if ( $mounts != {} ) {
    class { '::autofs::mounts': }
  }
}
