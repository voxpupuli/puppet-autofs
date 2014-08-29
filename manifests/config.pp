# /etc/puppetlabs/puppet/environments/elasticsearch/modules/autofs/manifests/config.pp

class autofs::config {

  File {
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { '/etc/auto.master': content => template('autofs/etc_auto_master.erb');}

  file { '/etc/auto.home': content => template('autofs/etc_auto_home.erb');}

  file { '/home':
    ensure  => 'link',
    target  => '/automount/home',
    force   => true,
    require => File['/automount/home']
  }

  file { '/automount': ensure => 'directory', }

  file { '/automount/home':
    ensure  => 'directory',
    require => File['/automount']
  }
}