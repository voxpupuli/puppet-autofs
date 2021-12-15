# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'autofs::map tests' do
  context 'basic map test' do
    it 'applies' do
      pp = <<-EOS
        class { 'autofs': }
        autofs::map { 'datamapA':
          mapfile     => '/etc/auto.data',
          mapcontents => [ 'dataA -o rw /mnt/dataA', 'dataB -o rw /mnt/dataB' ],
        }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.data') do
      it 'exists and have content' do
        expect(subject).to exist
        expect(subject).to be_owned_by 'root'
        expect(subject).to be_grouped_into 'root'
        expect(subject).to contain 'dataA -o rw /mnt/dataA'
        expect(subject).to contain 'dataB -o rw /mnt/dataB'
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

  context 'multiple entry maptest' do
    it 'applies' do
      pp = <<-EOS
        class { 'autofs': }
        autofs::map { 'datamapA':
          mapfile     => '/etc/auto.data',
          mapcontents => [ 'dataA -o rw /mnt/dataA', 'dataB -o rw /mnt/dataB' ],
        }
        autofs::map { 'datamapB':
          mapfile     => '/etc/auto.data',
          mapcontents => [ 'dataC -o rw /mnt/dataC', 'dataD -o rw /mnt/dataD' ],
        }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.data') do
      it 'exists and have content' do
        expect(subject).to exist
        expect(subject).to be_owned_by 'root'
        expect(subject).to be_grouped_into 'root'
        expect(subject).to contain 'dataA -o rw /mnt/dataA'
        expect(subject).to contain 'dataB -o rw /mnt/dataB'
        expect(subject).to contain 'dataC -o rw /mnt/dataC'
        expect(subject).to contain 'dataD -o rw /mnt/dataD'
      end
    end
  end

  context 'single entry maptest' do
    it 'applies' do
      pp = <<-EOS
        class { 'autofs': }
        autofs::map { 'datamapA':
          mapfile     => '/etc/auto.data',
          mapcontents => [ 'dataB -o rw /mnt/dataB' ],
        }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.data') do
      it 'exists and removes dataA entry' do
        expect(subject).to exist
        expect(subject).to be_owned_by 'root'
        expect(subject).to be_grouped_into 'root'
        expect(subject).not_to contain 'dataA -o rw /mnt/dataA'
        expect(subject).to contain 'dataB -o rw /mnt/dataB'
        expect(subject).not_to contain 'dataC -o rw /mnt/dataC'
        expect(subject).not_to contain 'dataD -o rw /mnt/dataD'
      end
    end
  end

  context 'rmmap entire' do
    it 'applies' do
      pp = <<-MANIFEST
        class { 'autofs': }
        autofs::map { 'datamapA':
          ensure  => 'absent',
          mapfile => '/etc/auto.data',
        }
      MANIFEST

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.data') do
      it 'does not exist' do
        expect(subject).not_to exist
      end
    end
  end
end
