# Defined Type Docmentation

define autofs::mount (
  $mount,
  $mapfile,
  $mapcontents,
) {
  file { $mount:
    ensure => directory,
  }

  file { "/etc/${mapfile}":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('etc/auto.map.erb'),
    require => File[ $mount ],
    notify  => Service[ 'autofs' ],
  }

}
