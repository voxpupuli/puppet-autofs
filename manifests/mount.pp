# Defined Type Docmentation

define autofs::mount (
  $mount,
  $mapfile,
  $mapcontents,
  $options,
  $order,
) {

  concat::fragment { "autofs::fragment preamble ${mount}":
    ensure         => present,
    target         => '/etc/auto.master',
    content        => "${mount} ${mapfile} ${options}\n",
    order          => $order,
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
