require 'spec_helper'
describe 'autofs::package', :type => :class do
  opsys = %w(
    Debian
    Ubuntu
    RedHat
    CentOS
    Suse
  )

  opsys.each do |os|
    context "install autofs #{os}" do
      let(:facts){ {:osfamily => "#{os}"} }

      it { is_expected.to contain_package('autofs').with_ensure('installed') }

    end
  end

end
