require 'spec_helper_acceptance'

describe 'autofs::map tests' do
  context 'basic map test' do
    it 'applies' do
      pp = <<-EOS
        class { 'autofs': }
        autofs::mount { '/mnt/datamap':
          mapfile => '/etc/auto.data',
        }
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
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
        is_expected.to be_mode 644
        is_expected.to contain 'dataA -o rw /mnt/dataA'
        is_expected.to contain 'dataB -o rw /mnt/dataB'
      end
      its(:content) do
        is_expected.to start_with('##')
        is_expected.not_to match %r{^(?m)data.*\n#}
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
        autofs::mount { '/mnt/datamap':
          mapfile => '/etc/auto.data',
        }
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
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
        is_expected.to be_mode 644
        is_expected.to contain 'dataA -o rw /mnt/dataA'
        is_expected.to contain 'dataB -o rw /mnt/dataB'
        is_expected.to contain 'dataC -o rw /mnt/dataC'
        is_expected.to contain 'dataD -o rw /mnt/dataD'
      end
      its(:content) do
        is_expected.to start_with('##')
        is_expected.not_to match %r{^(?m)data.*\n#}
      end
    end
  end

  context 'multiple entry maptest' do
    it 'applies' do
      pp = <<-EOS
        class { 'autofs': }
        autofs::mount { '/mnt/datamap':
          mapfile => '/etc/auto.data',
        }
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
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
        is_expected.not_to contain 'dataA -o rw /mnt/dataA'
        is_expected.to contain 'dataB -o rw /mnt/dataB'
        is_expected.not_to contain 'dataC -o rw /mnt/dataC'
        is_expected.not_to contain 'dataD -o rw /mnt/dataD'
      end
      # The content should start with the warning banner
      its(:content) { is_expected.to start_with '##' }
      # After the first map line, the banner should not be repeated
      its(:content) { is_expected.not_to match %r{^(?m)data.*\n#} }
    end
  end
end
