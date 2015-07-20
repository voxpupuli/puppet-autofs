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
