require 'spec_helper_acceptance'

describe 'autofs::map  tests' do
  context 'basic map test' do
    it 'applies' do
      pp = <<-EOS
        class { 'autofs': }
        autofs::mount { 'data':
          mount       => '/data',
          mapfile     => '/etc/auto.data',
          mapcontents => ['dataB -o rw /mnt/dataB'],
          options     => '--timeout=120',
          order       => 01
        }
	autofs::map {'dataC':
	  mapfile => '/etc/auto.data',
	  mapcontent => 'dataC -o rw /mnt/dataC',
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
          expect(s.stdout).to match(%r{/data /etc/auto.data --timeout=120})
        end
      end
    end

    describe file('/etc/auto.data') do
      it 'exists and have content' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
        shell('cat /etc/auto.data') do |s|
          expect(s.stdout).to match(%r{(dataA -o rw /mnt/dataA|dataC -o rw /mnt/dataC)})
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
