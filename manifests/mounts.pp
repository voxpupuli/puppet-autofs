# Defined Type Docmentation

define autofs::mounts (
  $confdir  = '/etc/',
  $owner      = 'root',
  $group      = 'root',
  $mode       = '0644',
  $ensure     = 'present',
  $content    = undef,
  $mountpoint = undef
) {
  file { "${confdir}/${title}":
    ensure  => $ensure,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => hiera($title)
  }
}
