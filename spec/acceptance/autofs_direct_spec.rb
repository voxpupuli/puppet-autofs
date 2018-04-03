require 'spec_helper_acceptance'

describe 'autofs::mount direct tests' do
  context 'basic direct test' do
    it 'applies' do
      pp = <<-EOS
        class { 'autofs': }
        autofs::mount { 'direct':
          mount       => '/-',
          mapfile     => '/etc/auto.direct',
          options     => '--timeout=120',
          order       => 01
        }
        autofs::mapfile { '/etc/auto.direct':
          mappings => [
            { 'key' => '/home/test_home', 'options' => 'rw', 'fs' => 'remote.com:/export/home' },
            { 'key' => '/tmp/test_tmp', 'options' => ['rw'], 'fs' => 'remote.com:/export/tmp' },
          ]
        }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.master') do
      it 'exists and is has correct ownership' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
      end
      its(:content) { is_expected.to match(%r{^/-\s+/etc/auto.direct\s+--timeout=120\s*$}) }
    end

    describe file('/etc/auto.direct') do
      it 'exists and has correct ownership' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
      end
      its(:content) do
        is_expected.to match(%r{^\s*/home/test_home\s+-rw\s+remote.com:/export/home\s*$})
        is_expected.to match(%r{^\s*/tmp/test_tmp\s+-rw\s+remote.com:/export/tmp\s*$})
      end
    end

    describe package('autofs') do
      it { is_expected.to be_installed }
    end

    describe service('autofs') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end
end
