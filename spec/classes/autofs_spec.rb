require 'spec_helper'
describe 'autofs', :type => :class do
  opsys = %w(
    Debian
    Ubuntu
    RedHat
    CentOS
    Solaris
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
      it { should contain_class('autofs')}
      it { should contain_class('autofs::package') }
      it { should contain_class('autofs::service') }
    end
  end

end
