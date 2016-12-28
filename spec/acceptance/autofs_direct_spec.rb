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

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    it 'should create files' do
      shell('test -e /etc/auto.direct', :acceptable_exit_codes => [0])
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
