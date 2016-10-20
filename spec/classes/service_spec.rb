require 'spec_helper'
describe 'autofs::service', :type => :class do

  context 'test default service' do
    it { should contain_service('autofs').with(
                    'hasstatus'  => 'true',
                    'hasrestart' => 'true',
                ).that_require('Package[autofs]')
    }
  end

end