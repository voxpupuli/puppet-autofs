# @summary Manages the autofs facility, optionally including configuring mount
#   points and maps.
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
#   class { 'autofs':
#     package_ensure => 'absent',
#   }
#
# @example Disable the autofs service
#   class { 'autofs':
#     service_ensure => 'stopped',
#     service_enable => false,
#   }
#
# @example using hiera with automatic lookup
#   ---
#   autofs::mounts:
#     home:
#       mount: '/home'
#       mapfile: '/etc/auto.home'
#       options: '--timeout=120'
#       order: 01
#   autofs::mapfiles:
#     '/etc/auto.home':
#       'mappings':
#         - key: '*'
#           options: 'user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl'
#           fs: 'server.example.com:/path/to/home/shares'
#
# @param mounts the options with which to manage the autofs master map
# @param purge_map_dir Purge the $map_dir directory of unmanaged
# @param ldap_auth_conf_path The path to the ldap_auth.conf file
# @param ldap_auth_config The hash to use for the configuration settings in the ldap_auth.conf file
# @param service_conf_path The path to the service configuration file
# @param service_options An array of options to add to the OPTIONS variable in the service configuration file
# @param service_conf_options A hash of environment variables to add to the service configuration file for LDAP configuration
# @param mapfiles replace: whether to modify the map file if it already exists
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
# @param manage_service_config Determines if the service configuration file (in /etc/default or /etc/sysconfig) should be managed
# @param manage_ldap_auth_conf Determines if the /etc/autofs_ldap_auth.conf file should be managed
# @param service_use_misc_device Sets the USE_MISC_DEVICE value in the service configuration file
# @param reload_command In lieu of a service reload capability in Puppet, exec this command to reload automount without restarting it.
# @param automountd_service_ensure Determines state of the service. Can be set to: running or stopped.
# @param autounmountd_service_ensure Determines state of the service. Can be set to: running or stopped.
# @param automountd_service_name Determine the name of the automountd service for cross platform compatibility
# @param autounmountd_service_name Determine the name of the autounmountd service for cross platform compatibility
#
class autofs (
  String $package_ensure = 'installed',
  Hash[String, Hash] $mounts = {},
  Variant[String, Array[String]] $package_name = 'autofs',
  Boolean $service_enable = true,
  String $service_name = 'autofs',
  String $auto_master_map = '/etc/auto.master',
  String $map_file_owner = 'root',
  String $map_file_group = 'root',
  Boolean $manage_service_config = false,
  Boolean $manage_ldap_auth_conf = false,
  Enum['no', 'yes'] $service_use_misc_device = 'yes',
  Boolean $purge_map_dir  = false,
  Enum['stopped', 'running'] $service_ensure = 'running',
  Stdlib::Absolutepath $ldap_auth_conf_path = '/etc/autofs_ldap_auth.conf',
  Hash $ldap_auth_config = { 'usetls' => 'no', 'tlsrequired' => 'no', 'authrequired' => 'no' },
  Stdlib::Absolutepath $service_conf_path = '/etc/sysconfig/autofs',
  Optional[Hash[String, Hash]] $mapfiles = undef,
  Optional[Hash[String, Hash]] $maps = undef,  # deprecated
  Optional[String] $package_source = undef,
  Optional[String] $reload_command = undef,
  Optional[Array[String]] $service_options = undef,
  Optional[Hash] $service_conf_options = undef,
  Optional[Enum['stopped', 'running']] $automountd_service_ensure = undef,
  Optional[Enum['stopped', 'running']] $autounmountd_service_ensure = undef,
  Optional[String] $automountd_service_name = undef,
  Optional[String] $autounmountd_service_name = undef,
) {
  contain 'autofs::package'
  unless $package_ensure == 'absent' {
    contain 'autofs::service'
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
