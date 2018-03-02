# Class: autofs
#
# Manages autofs mount points
#
# This class includes defined types for looping through arrays of configuration
# file names.
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see https://www.github.com/voxpupuli/puppet-autofs Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
#
# @author Vox Pupuli <voxpupuli@groups.io>
# @author David Hollinger III <david.hollinger@moduletux.com>
#
# To use this module, simply declare it in your manifest.
# @example Declaring the autofs class
#    include autofs
#
# The module now supports the ability to not only enable autofs,
# but to also disable or uninstall it completely.
# @example Removing the package
#    class { 'autofs':
#      package_ensure => 'absent',
#    }
#
# @example Disable the autofs service
#    class { 'autofs':
#      service_ensure => 'stopped',
#      service_enable => false,
#    }
#
#
# @example using hiera with automatic lookup
#    ---
#    autofs::mounts:
#      home:
#        mount: '/home'
#        mapfile: '/etc/auto.home'
#        mapcontents:
#          - '* -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl server.example.com:/path/to/home/shares'
#        options: '--timeout=120'
#        order: 01
#
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
# @param maps the options to build an autofs mapfile.
# @option maps [Array]:mapcontents Mount point options and parameters. Each
#   array element represents a line in the mapfile.
# @option maps [Stdlib::Absolutepath] :mapfile Full path to where the mapfile will be placed
# @option maps [Enum['autofs/auto.map.erb', 'autofs/auto.map.exec.erb']] :template Template to use the generate the mapfile
# @option maps [String] :mapmode The UNIX permissions to apply to the mapfile.
# @option maps [Boolean] :replace Replace the file if it changes or not.
# @option maps [Integer] :order The order in which to place mapfile contents.
# @param package_ensure Determines the state of the package. Can be set to: installed, absent, lastest, or a specific version string.
# @param package_name Determine the name of the package to install. Should be covered by hieradata.
# @param package_source Determine the source of the package, required on certain platforms (AIX)
# @param service_ensure Determines state of the service. Can be set to: running or stopped.
# @param service_enable Determines if the service should start with the system boot. true
#   will start the autofs service on boot. false will not start the autofs service
#   on boot.
# @param service_name Determine the name of the service for cross platform compatibility
# @param auto_master_map Filename of the auto.master map for cross platform compatiblity
# @param map_file_owner owner of the automount map files for cross platform compatiblity
# @param map_file_group group of the automount map files for cross platform compatiblity
# @param reload_command In lieu of a service reload capability in Puppet, exec this command to reload automount without restarting it.
#
class autofs (
  Hash[String, Hash] $mounts,
  Hash[String, Hash] $maps,
  String $package_ensure,
  Variant[String, Array[String]] $package_name,
  Optional[String] $package_source,
  Enum[ 'stopped', 'running' ] $service_ensure,
  Boolean $service_enable,
  String $service_name,
  String $auto_master_map,
  String $map_file_owner,
  String $map_file_group,
  Optional[String] $reload_command,
) {
  contain '::autofs::package'
  unless $package_ensure == 'absent' {
    contain '::autofs::service'
  }

  $mounts.each |String $mount, Hash $attributes| {
    autofs::mount { $mount: * => $attributes }
  }

  $maps.each |String $map, Hash $attributes| {
    autofs::map { $map: * => $attributes }
  }
}
