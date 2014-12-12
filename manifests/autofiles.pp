# Defined Type Docmentation

define autofs::autofiles (
  $confdir = '/etc/',
  $owner   = 'root',
  $group   = 'root',
  $mode    = '0644',
  $ensure  = 'present',
  $content = undef
) {
  file { "${confdir}/${title}":
    ensure  => $ensure,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => hiera("${confdir}/${title}"),
    notify  => Service[ 'autofs' ]
  }
}
