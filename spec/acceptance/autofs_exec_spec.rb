require 'spec_helper_acceptance'

describe 'autofs::mount exec tests' do
  context 'basic exec test' do
    it 'applies' do
      pp = <<-EOS
        class { 'autofs': }
        autofs::mount { 'exec':
          mount       => '/exec',
          mapfile     => '/etc/auto.exec',
          mapcontents => [ 'test_exec -o rw /mnt/test_exec' ],
          options     => '--timeout=120',
          order       => 01,
          execute     => true
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
        shell('cat /etc/auto.master') do |s|
          expect(s.stdout).to match(%r{/exec /etc/auto[.]exec --timeout=120})
        end
      end
    end

    describe file('/etc/auto.exec') do
      it 'exists and have content' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
        is_expected.to be_mode 755
      end
      its(:content) do
        is_expected.to start_with('#!/bin/bash')
        is_expected.to match(%r{^test_exec -o rw /mnt/test_exec$})
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

  context 'exec with use_dir test' do
    it 'applies' do
      pp = <<-EOS
        class { 'autofs': }
        autofs::mount { 'exec':
          mount       => '/exec',
          mapfile     => '/etc/auto.exec',
          mapcontents => [ 'test_exec -o rw /mnt/test_exec' ],
          options     => '--timeout=120',
          order       => 01,
          execute     => true,
          use_dir     => true,
          map_dir     => '/etc/auto.master.d',
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
      its(:content) { is_expected.to match(%r{^[+]dir:/etc/auto[.]master[.]d$}) }
    end

    describe file('/etc/auto.master.d/exec.autofs') do
      it 'exists and have content' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
        is_expected.to be_mode 644
      end
      its(:content) { is_expected.to match(%r{/exec /etc/auto[.]exec --timeout=120}) }
    end

    describe file('/etc/auto.exec') do
      it 'exists and have content' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
        is_expected.to be_mode 755
      end
      its(:content) do
        is_expected.to start_with('#!/bin/bash')
        is_expected.to match(%r{^test_exec -o rw /mnt/test_exec$})
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
