require 'spec_helper'
describe 'autofs::service', :type => :class do

  context 'test default service' do
    it { is_expected.to contain_service('autofs').with(
                    'hasstatus'  => 'true',
                    'hasrestart' => 'true',
                )
    }
  end

end