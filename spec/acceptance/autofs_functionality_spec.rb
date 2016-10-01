require 'spec_helper_acceptance'

describe 'autofs functionality tests' do
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

      apply_manifest(pp, :catch_failures => [0])
      apply_manifest(pp, :catch_changes => [0])
    end

    it 'should create files' do
      shell('test -e /etc/auto.home', :acceptable_exit_codes => [0])
      shell('test -e /etc/auto.master', :acceptable_exit_codes => [0])
    end

    it 'should have content in auto.home' do
      shell('cat /etc/auto.home') do |r|
        expect(r.stdout).to match(/test_home -o rw \/mnt\/test_home/)
      end
    end

    it 'should have content in master file' do
      shell('cat /etc/auto.master') do |s|
        expect(s.stdout).to match(/\/home \/etc\/auto.home --timeout=120/)
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

  context 'direct tests' do
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

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    it 'should create files' do
      shell('test -e /etc/auto.home', :acceptable_exit_codes => [0])
      shell('test -e /etc/auto.master', :acceptable_exit_codes => [0])
    end

    it 'should have master content' do
      shell('cat /etc/auto.master') do |r|
        expect(r.stdout).to match(/\/- \/etc\/auto.direct --timeout=120/)
      end
    end

    it 'should have direct content' do
      shell('cat /etc/auto.direct') do |s|
        expect(s.stdout).to match(/(\/home\/test_home -o rw \/mnt\/test_home|\/tmp\/test_tmp -o rw \/mnt\/test_tmp)/)
      end
    end

  end

end