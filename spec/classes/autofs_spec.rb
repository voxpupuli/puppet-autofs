require 'spec_helper'
describe 'autofs', :type => :class do
  opsys = %w(
    Debian
    Ubuntu
    RedHat
    CentOS
    Suse
  )

  opsys.each do |os|
    context 'main init tests' do
      let(:facts) do
        {
            :osfamily => "#{os}",
            :concat_basedir => '/etc'
        }
      end
      it { is_expected.to compile}
      it { is_expected.to contain_class('autofs')}
      it { is_expected.to contain_class('autofs::package') }
      it { is_expected.to contain_class('autofs::service') }

      # Check Package and service
      it { is_expected.to contain_package('autofs').with_ensure('installed') }
      it { is_expected.to contain_service('autofs').that_requires('Package[autofs]')}
    end
  end

end
