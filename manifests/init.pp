# /etc/puppetlabs/puppet/environments/elasticsearch/modules/autofs/manifests/init.pp

class autofs (
  $automount_ldap_server = $autofs::params::automount_ldap_server,
  $automount_home_server = $autofs::params::automount_home_server,
) inherits autofs::params {
  include autofs::config
}