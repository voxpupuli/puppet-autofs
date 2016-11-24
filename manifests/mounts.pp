# Class: autofs::mounts
#
class autofs::mounts () {
  $mount = hiera_hash ('autofs::mounts', [])

  create_resources('autofs::mount', $mount)
}
