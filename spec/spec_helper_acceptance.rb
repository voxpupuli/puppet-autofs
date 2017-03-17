require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'

run_puppet_install_helper unless ENV['BEAKER_provision'] == 'no'

RSpec.configure do |c|
  # Project root
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and deps
    hosts.each do |host|
      install_dev_puppet_module_on(host, source: module_root, module_name: 'autofs',
                                         target_module_path: '/opt/puppetlabs/puppet/modules')
      # Due to RE-6764, running yum update renders the machine unable to install
      # other software. Thus this workaround. - thanks to Gareth Rushgrove's work for this
      # if fact_on(host, 'operatingsystem') == 'RedHat'
      #  on(host, 'mv /etc/yum.repos.d/redhat.repo /etc/yum.repos.d/internal-mirror.repo')
      # end
      # on(host, 'yum update -y -q') if fact_on(host, 'osfamily') == 'RedHat'

      on host, puppet('module', 'install', 'puppetlabs-stdlib'), acceptable_exit_codes: [0, 1]
      on host, puppet('module', 'install', 'puppetlabs-concat'), acceptable_exit_codes: [0, 1]
    end
  end
end
