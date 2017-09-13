require 'spec_helper'

describe Facter::Util::Fact do
  before do
    Facter.clear
    Facter.fact(:kernel).stubs(:value).returns 'Linux'
  end

  describe 'autofs_version' do
    context 'autofs not in path' do
      before do
        Facter::Util::Resolution.stubs(:which).with('automount').returns(false)
      end
      it { expect(Facter.fact(:autofs_version).value).to eq(nil) }
    end

    context 'autofs' do
      before do
        Facter::Util::Resolution.stubs(:which).with('automount').returns(true)
        Facter::Core::Execution.stubs(:execute).with('automount -V 2>&1').returns('Linux automount version 5.1.1')
      end
      it { expect(Facter.fact(:autofs_version).value).to eq('5.1.1') }
    end
  end
end
