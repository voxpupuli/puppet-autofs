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

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    it 'should create files' do
      shell('test -e /etc/auto.exec', :acceptable_exit_codes => [0])
      shell('test -e /etc/auto.master', :acceptable_exit_codes => [0])
    end

    it 'should have master content' do
      shell('cat /etc/auto.master') do |r|
        expect(r.stdout).to match(/\/exec \/etc\/auto.exec --timeout=120/)
      end
    end

    it 'should have exec content' do
      shell('cat /etc/auto.exec') do |s|
        expect(s.stdout).to match(/test_exec -o rw \/mnt\/test_exec/)
      end
    end
  end

end