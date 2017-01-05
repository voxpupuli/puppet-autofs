require 'spec_helper_acceptance'

describe 'autofs::mount direct tests' do
  context 'basic direct test' do
    it 'applies' do
      pp = <<-EOS
        class { 'autofs': }
        autofs::mount { 'direct':
          mount       => '/-',
          mapfile     => '/etc/auto.direct',
          mapcontents => ['/home/test_home -o rw /mnt/test_home', '/tmp/test_tmp -o rw /mnt/test_tmp'],
          options     => '--timeout=120',
          order       => 01
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
        shell('cat /etc/auto.master') do |s|
          expect(s.stdout).to match(%r{/- /etc/auto.direct --timeout=120})
        end
      end
    end

    describe file('/etc/auto.direct') do
      it 'exists and have content' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
        shell('cat /etc/auto.direct') do |s|
          expect(s.stdout).to match(%r{(/home/test_home -o rw /mnt/test_home|/tmp/test_tmp -o rw /mnt/test_tmp)})
        end
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
