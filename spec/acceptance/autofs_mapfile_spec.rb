require 'spec_helper_acceptance'

describe 'autofs::mapfile used standalone' do
  context 'with simple configuration' do
    it 'applies' do
      pp = <<-EOS
        autofs::mapfile { '/etc/auto.data':
          mappings => [
            { 'key' => 'dataA', 'options' => 'ro', 'fs' => 'fs.net:/export/dataA' },
            { 'key' => 'dataB', 'options' => ['rw', 'noexec'], 'fs' => 'fs.net:/export/dataB' }
          ],
        }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.data') do
      it 'exists and belongs to root' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
      end
      its(:content) do
        is_expected.to match %r{^\s*dataA\s+-ro\s+fs.net:/export/dataA\s*$}
        is_expected.to match %r{^\s*dataB\s+-rw,noexec\s+fs.net:/export/dataB\s*$}
        is_expected.to match %r{\A##}
        is_expected.not_to match %r{^\s*data.*\n#}
      end
    end
  end

  context 'with multi-resource configuration' do
    it 'applies' do
      pp = <<-EOS
        autofs::mapfile { '/etc/auto.data':
          mappings => [
            { 'key' => 'dataA', 'options' => 'ro', 'fs' => 'fs.net:/export/dataA' },
            { 'key' => 'dataB', 'options' => ['rw', 'noexec'], 'fs' => 'fs.net:/export/dataB' }
          ],
        }
        autofs::mapping { 'dataC':
          mapfile => '/etc/auto.data',
          key     => 'dataC',
          options => 'rw',
          fs      => 'other.net:/export/dataC',
        }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.data') do
      it 'exists and belongs to root' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
      end
      its(:content) do
        is_expected.to match %r{^\s*dataA\s+-ro\s+fs.net:/export/dataA\s*$}
        is_expected.to match %r{^\s*dataB\s+-rw,noexec\s+fs.net:/export/dataB\s*$}
        is_expected.to match %r{^\s*dataC\s+-rw\s+other.net:/export/dataC\s*$}
      end
    end
  end

  context 'with no mappings' do
    it 'applies' do
      pp = <<-EOS
        autofs::mapfile { '/etc/auto.data':
        }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end
    describe file('/etc/auto.data') do
      it 'exists and belongs to root' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
      end
      its(:content) do
        is_expected.not_to match %r{^\s*\S(?<!#)}
      end
    end
  end

  context 'with path parameter' do
    it 'applies' do
      pp = <<-EOS
        autofs::mapfile { 'a map file':
          path => '/etc/auto.data',
          mappings => [
            { 'key' => 'dataQ', 'options' => 'ro', 'fs' => 'fs.net:/export/dataQ' },
            { 'key' => 'dataZ', 'options' => 'rw', 'fs' => 'fs.net:/export/dataZ' }
          ],
        }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.data') do
      it 'exists and belongs to root' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
      end
      its(:content) do
        is_expected.to match %r{^\s*dataQ\s+-ro\s+fs.net:/export/dataQ\s*$}
        is_expected.to match %r{^\s*dataZ\s+-rw\s+fs.net:/export/dataZ\s*$}
        is_expected.not_to match %r{data[^QZ]}
      end
    end
  end

  context 'rmmap entire' do
    it 'applies' do
      pp = <<-MANIFEST
        autofs::mapfile { '/etc/auto.data':
          ensure  => 'absent',
        }
      MANIFEST

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.data') do
      it 'does not exist' do
        is_expected.not_to exist
      end
    end
  end
end
