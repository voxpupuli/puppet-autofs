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
# These Parameters can be set statically,  within an ENC, or by using Hiera.
# See README Docs for Examples.
#
define autofs::mount (
  $mount,
  $mapfile,
  $mapcontents,
  $options,
  $order,
) {

  concat::fragment { "autofs::fragment preamble ${mount}":
    ensure  => present,
    target  => '/etc/auto.master',
    content => "${mount} ${mapfile} ${options}\n",
    order   => $order,
  }

  file { $mount:
    ensure  => directory,
    require => Package[ 'autofs' ],
  }

  file { $mapfile:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('autofs/auto.map.erb'),
    require => File[ $mount ],
    notify  => Service[ 'autofs' ],
  }

}
