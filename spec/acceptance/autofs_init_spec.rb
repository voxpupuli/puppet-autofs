require 'spec_helper_acceptance'

describe 'autofs' do
  it 'works with no errors' do
    pp = <<-EOS
      class { 'autofs': }
    EOS

    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_changes: true)
  end

  describe 'autofs::mount' do
    context 'basic tests' do
      it 'applies' do
        pp = <<-EOS
          class { 'autofs': }
          autofs::mount { 'home':
            mount       => '/home',
            mapfile     => '/etc/auto.home',
            mapcontents => ['test_home -o rw /mnt/test_home'],
            options     => '--timeout=120',
            order       => 01
          }
        EOS

        apply_manifest(pp, catch_failures: true)
      end

      describe file('/etc/auto.master') do
        it 'should exist and have content' do
          is_expected.to exist
          is_expected.to be_owned_by 'root'
          is_expected.to be_grouped_into 'root'
          shell('cat /etc/auto.master') do |s|
            expect(s.stdout).to match(/\/home \/etc\/auto.home --timeout=120/)
          end
        end
      end

      describe file('/etc/auto.home') do
        it 'should exist and have content' do
          is_expected.to exist
          is_expected.to be_owned_by 'root'
          is_expected.to be_grouped_into 'root'
          shell('cat /etc/auto.home') do |r|
            expect(r.stdout).to match(/test_home -o rw \/mnt\/test_home/)
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

    context 'master directory test' do
      it 'applies' do
        pp = <<-EOS
          class { 'autofs': }
          autofs::mount { 'confdir':
            mount       => '/mnt/confdir',
            mapfile     => '/etc/auto.confdir',
            mapcontents => ['test_dir -o rw /mnt/test_conf'],
            options     => '--timeout=120',
            order       => 02,
            use_dir     => true,
          }
        EOS

        apply_manifest(pp, catch_failures: true)
      end

      describe file('/etc/auto.master') do
        it 'should exist and have content' do
          is_expected.to exist
          is_expected.to be_owned_by 'root'
          is_expected.to be_grouped_into 'root'
          shell('cat /etc/auto.master') do |s|
            expect(s.stdout).to match(/\+dir\:\/etc\/auto.master.d/)
        end
      end

      describe file('/etc/auto.master.d') do
        it 'should be a directory owned by root' do
          is_expected.to be_directory
          is_expected.to be_owned_by 'root'
          is_expected.to be_grouped_into 'root'
        end
      end

      describe file('/etc/auto.master.d/confdir.autofs') do
        it 'should exist and have content' do
          is_expected.to exist
          is_expected.to be_owned_by 'root'
          is_expected.to be_grouped_into 'root'
          shell('cat /etc/auto.master.d/confdir.autofs') do |s|
            expect(s.stdout).to match(/\/mnt\/confdir \/etc\/auto.confdir --timeout=120/)
          end
        end
      end

      describe file('/etc/auto.confdir') do
        it 'should exist and have content' do
          is_expected.to exist
          is_expected.to be_owned_by 'root'
          is_expected.to be_grouped_into 'root'
          shell('cat /etc/auto.confdir') do |s|
            expect(s.stdout).to match(/test_dir -o rw \/mnt\/test_conf/)
          end
        end
      end

      end
    end

  end
end
