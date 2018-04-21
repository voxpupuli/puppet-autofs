# Class: autofs
#
# Manages the autofs facility, optionally including configuring
# mount points and maps.
#
# Autofs mount points and their corresponding maps can also be
# managed via separate autofs::mount, autofs::mapfile, and
# autofs::mapping resources.
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
# @example using hiera with automatic lookup
#    ---
#    autofs::mounts:
#      home:
#        mount: '/home'
#        mapfile: '/etc/auto.home'
#        options: '--timeout=120'
#        order: 01
#    autofs::mapfiles:
#      '/etc/auto.home':
#        'mappings':
#          - key: '*'
#            options: 'user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl'
#            fs: 'server.example.com:/path/to/home/shares'
#
# @param mounts the options with which to manage the autofs master map
# @option mounts [String] :mount The autofs mount point to be managed
# @option mounts [Integer] :order The relative order in which the mount point's
#   definition will appear in the master map
# @option mounts [String] :mapfile Name of the autofs map file for this mount point
# @option mounts [String] :options Mount options to be recorded for this mount point
#   in the master map
# @option mounts [String] :master Full path, including file name, to the master map
#   in which to manage this mount point
# @option mounts [String] :map_dir Full path, including file name, to the master map
#   drop-in directory in which to manage this mount's definition.  Relevant only when
#   :use_dir is set to true
# @option mounts [Boolean] :use_dir Whether to manage this mount via a file in the
#   master map's drop-in directory instead of directly in the master map
# @param mapfiles options with which to manage map files.
# @option mapfiles [String] path: Full path, including file name, to a
#   map file to manage.  Defaults to the key with which this value is associated.
# @option mapfiles [Array] mappings: an array of hashes defining specific, sun-format
#   mappings that should appear in this map file.  Each has a 'key', an option list in
#   string or array form, and a filesystem specification as expected by the 'mount'
#   command.
# @option mapfiles [Boolean] replace: whether to modify the map file if it already exists
# @param maps Deprecated.  Use the mapfiles parameter instead.
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
  String $package_ensure,
  Hash[String, Hash] $mounts,
  Variant[String, Array[String]] $package_name,
  Enum[ 'stopped', 'running' ] $service_ensure,
  Boolean $service_enable,
  String $service_name,
  String $auto_master_map,
  String $map_file_owner,
  String $map_file_group,
  Optional[Hash[String, Hash]] $mapfiles = undef,
  Optional[Hash[String, Hash]] $maps = undef,  # deprecated
  Optional[String] $package_source = undef,
  Optional[String] $reload_command = undef,
) {
  contain '::autofs::package'
  unless $package_ensure == 'absent' {
    contain '::autofs::service'
  }

  $mounts.each |String $mount, Hash $attributes| {
    autofs::mount { $mount: * => $attributes }
  }

  if $mapfiles =~ NotUndef {
    $mapfiles.each |String $file, Hash $attributes| {
      autofs::mapfile { $file: * => $attributes }
    }
  }

  if $maps =~ NotUndef {
    deprecation('autofs::maps', 'Class parameter $autofs::maps is deprecated and will be removed in a future version.  Define maps via the $mapfiles parameter instead')
    $maps.each |String $map, Hash $attributes| {
      autofs::map { $map: * => $attributes }
    }
  }
}
