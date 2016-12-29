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

        apply_manifest(pp, :catch_failures => [0])
      end

      describe file('/etc/auto.master') do
        it { is_expected.to exist }
        it { is_expected.to be_owned_by 'root' }
        it { is_expected.to be_grouped_into 'root' }
        it 'should have content in master file' do
          shell('cat /etc/auto.master') do |s|
            expect(s.stdout).to match(/\/home \/etc\/auto.home --timeout=120/)
          end
        end
      end

      describe file('/etc/auto.home') do
        it { is_expected.to exist }
        it { is_expected.to be_owned_by 'root' }
        it { is_expected.to be_grouped_into 'root' }
        it 'should have content in auto.home' do
          shell('cat /etc/auto.home') do |r|
            expect(r.stdout).to match(/test_home -o rw \/mnt\/test_home/)
          end
        end
      end

      # it 'should create files' do
      #   shell('test -e /etc/auto.home', :acceptable_exit_codes => [0])
      #   shell('test -e /etc/auto.master', :acceptable_exit_codes => [0])
      # end
      #
      # it 'should have content in auto.home' do
      #   shell('cat /etc/auto.home') do |r|
      #     expect(r.stdout).to match(/test_home -o rw \/mnt\/test_home/)
      #   end
      # end
      #
      # it 'should have content in master file' do
      #   shell('cat /etc/auto.master') do |s|
      #     expect(s.stdout).to match(/\/home \/etc\/auto.home --timeout=120/)
      #   end
      # end

      describe package('autofs') do
        it { is_expected.to be_installed }
      end

      describe service('autofs') do
        it { is_expected.to be_enabled }
        it { is_expected.to be_running }
      end
    end

  end
end
