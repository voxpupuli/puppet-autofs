# Defined Type Docmentation

define autofs::mount (
  $mountdir = '/automount',
  $owner    = 'root',
  $group    = 'root',
  $mode     = '0755',
  $ensure   = 'directory',
  $require  = unset
) {
  file { "${mountdir}/${title}":
    ensure => $ensure,
    owner  => $owner,
    group  => $group,
    mode   => $mode
  }
}
