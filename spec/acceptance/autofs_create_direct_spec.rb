require 'spec_helper_acceptance'

describe 'autofs::mount::direct' do
  let(:pp) {"
    file { '/mnt/test_home': ensure => directory }
    file { '/mnt/foo_home': ensure => directory }
    class { 'autofs': }
    autofs::mount { 'direct':
      mount       => '/home',
      mapfile     => '/etc/auto.home',
      mapcontents => [ '/home/test /mnt/test_home', '/home/foo /mnt/foo_home' ],
      options     => '--timeout=120',
      order       => 01,
      use_dir     => true
    }
  "}

  it 'should run without errors' do
    apply_manifest(pp, :catch_failures => true)
  end

  it 'should be idempotent' do
    apply_manifest(pp, :catch_changes => true)
  end

  it 'should add config files' do
    shell('test -e /etc/auto.home', :acceptable_exit_codes => [0])
    shell('test -e /etc/auto.master', :acceptable_exit_codes => [0])
    shell('test -d /etc/auto.master.d', :acceptable_exit_codes => [0])
    shell('test -e /etc/auto.master.d/direct.autofs', :acceptable_exit_codes => [0])
  end

  describe package('autofs') do
    it { is_expected.to be_installed}
  end

  describe service('autofs') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end
end