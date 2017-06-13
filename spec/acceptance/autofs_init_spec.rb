require 'spec_helper_acceptance'

describe 'autofs' do
  def cleanup_helper
    pp = <<-EOS
      package { 'autofs': ensure => 'absent', }
      file { '/etc/auto.home': ensure => 'absent', }
      file { '/etc/auto.master': ensure => 'absent', }
      file { '/etc/auto.confdir': ensure => 'absent', }
      file { '/etc/auto.master.d':
        ensure => 'absent',
        recurse => true,
        purge => true,
        force => true,
      }
    EOS
    apply_manifest(pp, catch_failures: true)
  end

  before(:context) do
    cleanup_helper
  end

  it 'works with no errors' do
    pp = <<-EOS
      class { 'autofs': }
    EOS

    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_changes: true)
  end

  describe 'autofs::mount' do
    shared_examples 'basic tests' do
      describe file('/etc/auto.master') do
        it 'exists and have content' do
          is_expected.to exist
          is_expected.to be_owned_by 'root'
          is_expected.to be_grouped_into 'root'
          shell('cat /etc/auto.master') do |s|
            expect(s.stdout).to match(%r{/home /etc/auto.home --timeout=120})
          end
        end
      end

      describe file('/etc/auto.home') do
        it 'exists and have content' do
          is_expected.to exist
          is_expected.to be_owned_by 'root'
          is_expected.to be_grouped_into 'root'
          shell('cat /etc/auto.home') do |r|
            expect(r.stdout).to match(%r{test_home -o rw /mnt/test_home})
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

    context 'basic tests - mount defined with defined type' do
      before(:context) do
        cleanup_helper
      end

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

      include_examples 'basic tests'
    end

    context 'basic tests - mount defined by autofs class parameter' do
      before(:context) do
        cleanup_helper
      end

      it 'applies' do
        pp = <<-EOS
          class { 'autofs':
            mounts =>  {
              'home' => {
                mount       => '/home',
                mapfile     => '/etc/auto.home',
                mapcontents => ['test_home -o rw /mnt/test_home'],
                options     => '--timeout=120',
                order       => 01
              },
            },
          }
        EOS

        apply_manifest(pp, catch_failures: true)
      end

      include_examples 'basic tests'
    end

    context 'master directory test' do
      before(:context) do
        cleanup_helper
      end

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
        it 'exists and have content' do
          is_expected.to exist
          is_expected.to be_owned_by 'root'
          is_expected.to be_grouped_into 'root'
          shell('cat /etc/auto.master') do |s|
            expect(s.stdout).to match(%r{\+dir:/etc/auto.master.d})
          end
        end

        describe file('/etc/auto.master.d') do
          it 'is a directory owned by root' do
            is_expected.to be_directory
            is_expected.to be_owned_by 'root'
            is_expected.to be_grouped_into 'root'
          end
        end

        describe file('/etc/auto.master.d/confdir.autofs') do
          it 'exists and have content' do
            is_expected.to exist
            is_expected.to be_owned_by 'root'
            is_expected.to be_grouped_into 'root'
            shell('cat /etc/auto.master.d/confdir.autofs') do |s|
              expect(s.stdout).to match(%r{/mnt/confdir /etc/auto.confdir --timeout=120})
            end
          end
        end

        describe file('/etc/auto.confdir') do
          it 'exists and have content' do
            is_expected.to exist
            is_expected.to be_owned_by 'root'
            is_expected.to be_grouped_into 'root'
            shell('cat /etc/auto.confdir') do |s|
              expect(s.stdout).to match(%r{test_dir -o rw /mnt/test_conf})
            end
          end
        end
      end
    end

    context 'package set to absent' do
      before(:context) do
        cleanup_helper
      end

      it 'applies' do
        pp = <<-EOS
          class { 'autofs':
            package_ensure => 'absent',
          }
        EOS

        apply_manifest(pp, catch_failures: true)
        apply_manifest(pp, catch_changes: true)
      end

      describe package('autofs') do
        it { is_expected.not_to be_installed }
      end
    end

    context 'package installed but service disabled' do
      before(:context) do
        cleanup_helper
      end

      it 'applies' do
        pp = <<-EOS
          class { 'autofs':
            service_ensure => 'stopped',
            service_enable => false,
          }
        EOS

        apply_manifest(pp, catch_failures: true)
        apply_manifest(pp, catch_changes: true)
      end

      describe package('autofs') do
        it { is_expected.to be_installed }
      end

      describe service('autofs') do
        it { is_expected.not_to be_running }
      end

      unless default[:platform] =~ %r{ubuntu-14.04-amd64}
        describe service('autofs') do
          it { is_expected.not_to be_enabled }
        end
      end
    end
  end
end
