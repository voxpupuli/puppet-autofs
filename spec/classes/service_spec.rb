require 'spec_helper'
describe 'autofs::service', :type => :class do

  context 'test default service' do
    let(:params) do
      {
          :service_ensure => 'running',
          :service_enable => 'true'
      }
    end
    it { should contain_service('autofs').with(
                    'ensure' => :service_ensure,
                    'enable' => :service_enable,
                    'hasstatus' => 'true',
                    'hasrestart' => 'true',
                )
    }
  end

end