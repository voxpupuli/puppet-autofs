require 'spec_helper'

describe Facter::Util::Fact do
  before do
    Facter.clear
    allow(Facter.fact(:kernel)).to receive(:value).and_return('Linux')
  end

  describe 'autofs_version' do
    context 'autofs not in path' do
      before do
        allow(Facter::Util::Resolution).to receive(:which).with('automount').and_return(false)
      end
      it { expect(Facter.fact(:autofs_version).value).to eq(nil) }
    end

    context 'autofs' do
      before do
        allow(Facter::Util::Resolution).to receive(:which).with('automount').and_return(true)
        allow(Facter::Util::Resolution).to receive(:exec).with('automount -V 2>&1').and_return('Linux automount version 5.1.1')
      end
      it { expect(Facter.fact(:autofs_version).value).to eq('5.1.1') }
    end
  end
end
