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
#
# [*options*]
#  Options for the autofs mount point within in the auto.master
#
# [*order*]
#  Order in which entries will appear in the autofs master file.
#
# [*direct*]
#  Boolean to allow for indirect map. Defaults to true to be backwards compatible.
#
# [*execute*]
#  Boolean to set the map to be executable. Defaults to false to be backward compatible.
#
# [*replace*]
#  Boolean to set the map file to not be replaced. Defaults to true as Puppet File resource does.
#
# These Parameters can be set statically,  within an ENC, or by using Hiera.
# See README Docs for Examples.
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
