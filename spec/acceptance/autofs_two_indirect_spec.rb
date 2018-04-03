require 'spec_helper_acceptance'

describe 'autofs::mount indirect tests' do
  context 'two indirect test, order not specified' do
    it 'applies' do
      pp = <<-EOS
        class { 'autofs': }
        autofs::mount { 'foo':
          mount       => '/foo',
          mapfile     => '/etc/auto.foo',
          options     => '--timeout=120',
        }
        autofs::mapfile { '/etc/auto.foo':
          mappings => [ { 'key' => 'FOO', 'options' => 'rw', 'fs' => 'remote.org:/export/FOO' } ]
        }
        autofs::mount { 'bar':
          mount       => '/bar',
          mapfile     => '/etc/auto.bar',
          options     => '--timeout=240',
        }
        autofs::mapfile { '/etc/auto.bar':
          mappings => [ { 'key' => 'BAR', 'options' => 'rw', 'fs' => 'remote.org:/export/BAR' } ]
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
      end
      its(:content) do
        is_expected.to match %r{^\s*/foo\s+/etc/auto.foo\s+--timeout=120\s*$}
        is_expected.to match %r{^\s*/bar\s+/etc/auto.bar\s+--timeout=240\s*$}
      end
    end

    describe file('/etc/auto.foo') do
      it 'exists and is owned by root' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
      end
      its(:content) { is_expected.to match %r{^\s*FOO\s+-rw\s+remote.org:/export/FOO\s*$} }
    end

    describe file('/etc/auto.bar') do
      it 'exists and is owned by root' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
      end
      its(:content) { is_expected.to match %r{^\s*BAR\s+-rw\s+remote.org:/export/BAR\s*$} }
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
