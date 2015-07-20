# Class: autofs::mounts
#
class autofs::mounts( $mount ){
  concat { '/etc/auto.master':
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Service[ 'autofs' ],
  }
  
  create_resources('autofs::mount', $mount)
}
