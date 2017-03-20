require 'spec_helper'

describe Facter::Util::Fact do
  before { Facter.clear }
  after { Facter.clear }

  context 'autofs not in path' do
    before do
      Facter::Util::Resolution.stubs(:which).with('automount').returns(false)
    end
    it { expect(Facter.fact(:autofs_version).value).to eq(nil) }
  end
  context 'autofs' do
    before do
      Facter::Util::Resolution.stubs(:which).with('automount').returns(true)
      Facter::Util::Resolution.stubs(:exec).with('automount -V 2>&1').returns('Linux automount version 5.1.1')
    end
    it { expect(Facter.fact(:autofs_version).value).to eq('5.1.1') }
  end
end
