# Define: autofs::map
#
# Defined type to manage mappings in Autofs map files that are managed
# via autofs::mount instances.  It is an error to declare an autofs::mount
# with a $mapfile for which there is not also an autofs::mount declared,
# whether via manifest code or via equivalent data.  Multiple autofs::map
# resources can contribute content to the same map file, and such content
# is combined with any specified via the corresponding autofs::mount.
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see https://voxpupuli.org/puppet-autofs/puppet_classes/autofs.html puppet_classes::autofs
# @see https://www.github.com/voxpupuli/puppet-autofs Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
#
# @author Vox Pupuli <voxpupuli@groups.io>
# @author David Hollinger III <david.hollinger@moduletux.com>
#
# @example Using autofs::map together with autofs::mount to set up
#   automounting for several NFS filesystems
#   @autofs::mount { 'example':
#     mount   => '/mnt/example',
#     mapfile => '/etc/auto.example',
#   }
#   @autofs::map { 'fs1':
#     mapfile     => '/etc/auto.example',
#     mapcontents => [
#       'fs1 -rw nfs.example.org:/path/to/fs1',
#       'fs2 -ro nfs.example.org:/path/to/fs2'
#     ],
#   }
#   @autofs::map { 'fs3':
#     mapfile     => '/etc/auto.example',
#     mapcontents => [
#       'fs3 -rw other.example.org:/path/to/fs3'
#     ],
#   }
#
# @param ensure Whether the contents of the map should be present in the
#   target map file.  Does not influence the presence or absence of the map
#   file itself.  Affirmatively ensuring 'absent' has the same effect as
#   omitting the resource declaration altogether (default: 'present').
# @param mapfile Path to the map file for which this resource provides contents
# @param mapcontents A filesystem mapping or an array of them, each in Autofs
#   map file format.  In principle, this should instead be shell script code
#   if the target mapfile is an executable map, but it is not recommended or
#   supported to use autofs::map resources for such map files.
#   Example: ['* -rw nfs.example.org:/path/to']
# @param order The order in which the contents given by this resource
#   will appear in the designated map file, relative to contents specified
#   by other 'autofs::map' resources, by the corresponding 'autofs::mount'
#   resource (50), or by the corresponding (external-)data representations of
#   these.  The seqence of map entries matters only when there are multiple
#   mappings matching the same key. (default: 50)
# @param mapmode DEPRECATED: has no effect, and may be omitted
# @param replace DEPRECATED: has no effect, and may be omitted
# @param template DEPRECATED: has no effect, and may be omitted
#
define autofs::map (
  Enum['present', 'absent'] $ensure                                 = 'present',
  Stdlib::Absolutepath $mapfile                                     = $title,
  Optional[String] $template                                        = undef,     # ignored
  Optional[String] $mapmode                                         = undef,     # ignored
  Optional[Boolean] $replace                                        = undef,     # ignored
  Integer $order                                                    = 50,
  Variant[Array[String], String] $mapcontents                       = [],
) {
  include '::autofs'

  if $template =~ NotUndef {
    deprecation('autofs::map::template',
        'Parameter $template of autofs::map is deprecated and has no effect.  Do not use it.')
  }

  if $mapmode =~ NotUndef {
    deprecation('autofs::map::mapmode',
        'Parameter $mapmode of autofs::map is deprecated and has no effect.  Use $autofs::mount::execute instead.')
  }

  if $replace =~ NotUndef {
    deprecation('autofs::map::replace',
        'Parameter $replace of autofs::map is deprecated and has no effect.  Use $autofs::mount::replace instead.')
  }

  unless $ensure == 'absent' {
    concat::fragment { "${mapfile}_${name}_entries":
      target  => $mapfile,
      content => template('autofs/auto.map.erb'),
      order   => $order,
    }
  }
}
