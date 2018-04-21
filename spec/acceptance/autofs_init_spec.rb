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
        end
        its(:content) do
          is_expected.to match %r{^\s*/home\s+/etc/auto.home\s+--timeout=120\s*$}
        end
      end

      describe file('/etc/auto.home') do
        it 'exists and is owned by root' do
          is_expected.to exist
          is_expected.to be_owned_by 'root'
          is_expected.to be_grouped_into 'root'
        end
        its(:content) do
          is_expected.to match %r{^\s*test_home\s+-rw\s+remote.org:/export/home\s*$}
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

    context 'basic tests - mount and map file defined with defined types' do
      before(:context) do
        cleanup_helper
      end

      it 'applies' do
        pp = <<-EOS
          class { 'autofs': }
          autofs::mount { 'home':
            mount       => '/home',
            mapfile     => '/etc/auto.home',
            options     => '--timeout=120',
            order       => 01
          }
          autofs::mapfile { '/etc/auto.home':
            mappings => [{ 'key' => 'test_home', 'options' => 'rw', 'fs' => 'remote.org:/export/home' }]
          }
        EOS

        apply_manifest(pp, catch_failures: true)
      end

      include_examples 'basic tests'
    end

    context 'basic tests - mount and map file defined by autofs class parameters' do
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
                options     => '--timeout=120',
                order       => 01
              },
            },
            mapfiles => {
              '/etc/auto.home' => {
                mappings => [
                  { 'key' => 'test_home', 'options' => 'rw', 'fs' => 'remote.org:/export/home' }
                ]
              }
            }
          }
        EOS

        apply_manifest(pp, catch_failures: true)
      end

      include_examples 'basic tests'
    end

    context 'without home map' do
      it 'applies' do
        pp = <<-MANIFEST
          class { 'autofs':
            mounts => {
              'home' => {
                ensure  => 'absent',
                mount   => '/home',
                mapfile => '/etc/auto.home',
              }
            }
          }
        MANIFEST

        apply_manifest(pp, catch_failures: true)
      end

      describe file('/etc/auto.master') do
        it do
          is_expected.to exist
          is_expected.to be_file
          is_expected.to be_owned_by 'root'
          is_expected.to be_grouped_into 'root'
        end

        its(:content) { is_expected.not_to match %r{^\s*/home\s} }
      end
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
            options     => '--timeout=120',
            order       => 02,
            use_dir     => true,
          }
        EOS

        apply_manifest(pp, catch_failures: true)
      end

      describe file('/etc/auto.master') do
        it 'exists and belongs to root' do
          is_expected.to exist
          is_expected.to be_owned_by 'root'
          is_expected.to be_grouped_into 'root'
        end
        its(:content) do
          is_expected.to match %r{^\s*\+dir:/etc/auto.master.d\s*$}
          is_expected.not_to match %r{^\s*/mnt/confdir\s}
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
        it 'exists and is owned by root' do
          is_expected.to exist
          is_expected.to be_owned_by 'root'
          is_expected.to be_grouped_into 'root'
        end
        its(:content) do
          is_expected.to match %r{^\s*/mnt/confdir\s+/etc/auto.confdir\s+--timeout=120\s*$}
          is_expected.not_to match %r{\n.}
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
