require 'spec_helper'
describe 'autofs::package', :type => :class do
  opsys = %w(
    Debian
    Ubuntu
    RedHat
    CentOS
  )

  opsys.each do |os|
    describe "install autofs #{os}" do
      let(:facts){ {:osfamily => "#{os}"} }

      it { should contain_package('autofs').with_ensure('installed') }

    end
  end

end