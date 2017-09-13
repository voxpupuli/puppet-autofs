# Define: autofs::map
#
# Defined type to generate autofs map entry
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
# @example Using the autofs::map defined type to setup automount for nfs data directory.
#   autofs::map { 'data':
#     mapcontents => 'mydata -user,rw,soft,intr,rsize=32768,wsize=32768  nfs.example.org:/path/to/some/data',
#     mapfile => '/etc/auto.data',
#     order   => '01',
#   }
#
# @param mapcontents The mount point options and parameters, 
#   Example: '* -user,rw,soft nfs.example.org:/path/to'
# @param mapfile Name of the "auto." configuration file that will be generated.
# @param template Template to use to generate the mapfile.
# @param mapmode UNIX permissions to be added to the file.
# @param replace Whether or not to replace an existing mapfile of the same filename/path.
# @param order Order in which entries will appear in the autofs map file.
#
define autofs::map (
  Array $mapcontents,
  Stdlib::Absolutepath $mapfile,
  Enum['autofs/auto.map.erb', 'autofs/auto.map.exec.erb'] $template = 'autofs/auto.map.erb',
  String $mapmode                                                   = '0644',
  Boolean $replace                                                  = true,
  Integer $order                                                    = 1,
) {
  ensure_resource(concat,$mapfile,{
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => $mapmode,
    replace => $replace,
    require => Class['autofs::package'],
    notify  => Service['autofs'],
  })

  concat::fragment{"${mapfile}_${name}_entries":
    target  => $mapfile,
    content => template($template),
    order   => $order,
  }

}
