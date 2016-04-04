# == Define: autofs::mount
#
# Define to generate autofs mount point
# configuration files.
#
# === Parameters
# [*mount*]
#  Location where you will mount the remote
#  NFS Share.
#
# [*mapfile*]
#  Name of the "auto." file that will be generated
#
# [*mapcontents*]
#  The mount point options and parameters,
#  Example: '* -user,rw,soft server.example.com:/path/to/home/shares'
#
# [*options*]
#  Options for the autofs mount point within in the auto.master
#
# [*order*]
#  Order in which entries will appear in the autofs master file.
#
# [*direct*]
#  Boolean to allow for indirect map. Defaults to true to be backwards compatible.
#
# [*execute*]
#  Boolean to set the map to be executable. Defaults to false to be backward compatible.
#
# These Parameters can be set statically,  within an ENC, or by using Hiera.
# See README Docs for Examples.
#
define autofs::mount (
  $mount,
  $mapfile,
  $mapcontents,
  $options,
  $order,
  $direct=true,
  $execute=false
) {

  concat::fragment { "autofs::fragment preamble ${mount} ${mapfile}":
    ensure  => present,
    target  => '/etc/auto.master',
    content => "${mount} ${mapfile} ${options}\n",
    order   => $order,
  }

  if $execute {
    $mapperms = '0755'
    $maptempl = 'autofs/auto.map.exec.erb'
  }
  else {
    $mapperms = '0644'
    $maptempl = 'autofs/auto.map.erb'
  }

  file { $mapfile:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => $mapperms,
    content => template($maptempl),
    require => Package[ 'autofs' ],
    notify  => Service[ 'autofs' ],
  }

}
