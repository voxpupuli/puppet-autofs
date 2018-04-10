
require 'spec_helper_acceptance'

describe 'autofs::mount tests' do
  context 'basic mount test' do
    before(:context) do
      pp = "file { '/etc/auto.data': ensure => 'absent' }"
      apply_manifest(pp, catch_failures: true)
    end

    it 'applies' do
      pp = <<-EOS
        class { 'autofs': }
        autofs::mount { '/mnt/data':
          mapfile     => '/etc/auto.data',
        }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.master') do
      it 'exists and have content' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
        is_expected.to be_mode 644
      end
      its(:content) { is_expected.to match(%r{^\s*/mnt/data\s+/etc/auto.data\s*$}) }
    end

    describe file('/etc/auto.data') do
      it { is_expected.not_to exist }
    end

    describe package('autofs') do
      it { is_expected.to be_installed }
    end

    describe service('autofs') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end

  context 'remove mountpoint test' do
    before(:context) do
      apply_manifest("file { '/etc/auto.data': ensure => 'file', content => 'TEST CONTENT' }",
                     catch_failures: true)
    end

    it 'applies' do
      pp = <<-MANIFEST
        class { 'autofs': }
        autofs::mount { 'data':
          ensure        => 'absent',
          mount         => '/mnt/data',
          mapfile       => '/etc/auto.data',
        }
      MANIFEST

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.data') do
      it 'is unaffected' do
        is_expected.to exist
        is_expected.to contain 'TEST CONTENT'
      end
    end

    describe file('/etc/auto.master') do
      it 'exists and have content' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
        is_expected.to be_mode 644
      end
      its(:content) { is_expected.not_to match(%r{^\s*/mnt/data\s}) }
    end
  end
end
