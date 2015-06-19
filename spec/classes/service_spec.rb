require 'spec_helper'
describe 'autofs::service', :type => :class do

  context 'test default service' do
    it { should contain_service('autofs').with(
                    'ensure' => 'running',
                    'enable' => 'true',
                    'hasstatus' => 'true',
                    'hasrestart' => 'true',
                )
    }
  end

end