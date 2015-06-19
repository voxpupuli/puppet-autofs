require 'spec_helper'
describe 'autofs', :type => :class do

  context 'main init tests' do
    let(:facts) do
      {
        :osfamily => 'RedHat',
        :concat_basedir => '/etc'
      }
    end
    it { should contain_class('autofs::package') }
    it { should contain_class('autofs::config') }
    it { should contain_class('autofs::service') }
  end

end
