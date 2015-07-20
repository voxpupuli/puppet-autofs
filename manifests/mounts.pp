# Class: autofs::mounts
#
class autofs::mounts( $mount ){
  create_resources('autofs::mount', $mount)
}
