# /etc/puppetlabs/puppet/environments/elasticsearch/modules/autofs/manifests/params.pp

class autofs::params {
  $automount_ldap_server = hiera('automount_ldap_server')
  $automount_home_server = hiera('automount_home_server')
}