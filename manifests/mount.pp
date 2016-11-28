# Define: autofs::mount
#
# Defined type to generate autofs mount point
# configuration files.
#
# @see autofs
#
# @example Using the autofs::mount defined type to setup automount for user home directories.
#   autofs::mount { 'home':
#     mount       => '/home',
#     mapfile     => '/etc/auto.home',
#     mapcontents => ['* -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl server.example.com:/path/to/home/shares'],
#     options     => '--timeout=120',
#     order       => 01
#   }
#
# @param mount Location where you will mount the remote NFS Share.
# @param mapfile Name of the "auto." configuration file that will be generated.
# @param mapcontents The mount point options and parameters.
#   Example: '* -user,rw,soft server.example.com:/path/to/home/shares'
# @param options Options for the autofs mount point within in the auto.master.
# @param order Order in which entries will appear in the autofs master file.
# @param direct Boolean to allow for indirect map. Defaults to true to be
#   backwards compatible.
# @param execute If true, it will make the $mapfile an executable script,
#   otherwise the file is a standard "auto." configuration file.
# @param replace Set to false if you only want to place the file if it is missing.
#
define autofs::mount (
  String $mount,
  Integer $order,
  String $options    = '',
  String $master     = '/etc/auto.master',
  String $map_dir    = '/etc/auto.master.d',
  Boolean $use_dir   = false,
  Boolean $direct    = true,
  Boolean $execute   = false,
  String $mapfile    = '',
  Array $mapcontents = [],
  Boolean $replace   = true
) {

  if $mapfile != '' {
    $contents = "${mount} ${mapfile} ${options}\n"
  } else {
    $contents = "${mount} ${options}\n"
  }

  if $execute {
    $mapperms = '0755'
    $maptempl = 'autofs/auto.map.exec.erb'
  }
  else {
    $mapperms = '0644'
    $maptempl = 'autofs/auto.map.erb'
  }

  if !defined(Concat[$master]) {
    concat { $master:
      owner          => 'root',
      group          => 'root',
      mode           => '0644',
      ensure_newline => true,
      notify         => Service[ 'autofs' ],
    }
  }

  if $use_dir == false {
    concat::fragment { "autofs::fragment preamble ${mount} ${mapfile}":
      target  => $master,
      content => $contents,
      order   => $order,
    }
  } else {
    ensure_resource('file', $map_dir, {
      'ensure' => 'directory',
      'owner'  => 'root',
      'group'  => 'root',
      'mode'   => '0755',
    })

    if !defined(Concat::Fragment['autofs::fragment preamble map directory']) {
      concat::fragment { 'autofs::fragment preamble map directory':
        target  => $master,
        content => "+dir:${map_dir}",
        order   => $order,
        require => File[ $map_dir ],
      }
    }

    file { "${map_dir}/${name}.autofs":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => $mapperms,
      content => $contents,
      require => File[ $map_dir ],
      notify  => Service[ 'autofs' ],
    }
  }

  if $mapfile != '' {
    file { $mapfile:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => $mapperms,
      replace => $replace,
      content => template($maptempl),
      require => Package[ 'autofs' ],
      notify  => Service[ 'autofs' ],
    }
  }

}
