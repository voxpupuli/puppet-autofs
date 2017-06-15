require 'spec_helper_acceptance'

describe 'autofs::mount indirect tests' do
  context 'two indirect test, order not specified' do
    it 'applies' do
      pp = <<-EOS
        class { 'autofs': }
        autofs::mount { 'foo':
          mount       => '/foo',
          mapfile     => '/etc/auto.foo',
          mapcontents => ['FOO -o rw /mnt/test_FOO'],
          options     => '--timeout=120',
        }
        autofs::mount { 'bar':
          mount       => '/bar',
          mapfile     => '/etc/auto.bar',
          mapcontents => ['BAR -o rw /mnt/test_BAR'],
          options     => '--timeout=240',
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
        is_expected.to contain '/foo /etc/auto.foo --timeout=120'
        is_expected.to contain '/bar /etc/auto.bar --timeout=240'
      end
    end

    describe file('/etc/auto.foo') do
      it 'exists and have content' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
        is_expected.to contain 'FOO -o rw /mnt/test_FOO'
      end
    end

    describe file('/etc/auto.bar') do
      it 'exists and have content' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
        is_expected.to contain 'BAR -o rw /mnt/test_BAR'
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
