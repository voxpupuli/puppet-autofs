# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'autofs::mapping tests' do
  context 'basic mapping test' do
    it 'applies' do
      pp = <<-EOS
        autofs::mapfile { '/etc/auto.data':
        }
        autofs::mapping { 'dataA':
          mapfile => '/etc/auto.data',
          key     => 'dataA',
          options => 'ro',
          fs      => 'fs.net:/export/dataA',
        }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.data') do
      it 'exists and belongs to root' do
        expect(subject).to exist
        expect(subject).to be_owned_by 'root'
        expect(subject).to be_grouped_into 'root'
      end

      its(:content) do
        is_expected.to match %r{^\s*dataA\s+-ro\s+fs.net:/export/dataA\s*$}
      end
    end
  end

  context 'with order parameter' do
    it 'applies' do
      pp = <<-EOS
        autofs::mapfile { '/etc/auto.data':
          mappings => [
            { 'key' => 'dataB', 'options' => 'rw,noexec', 'fs' => 'fs.net:/export/dataB', 'order' => 20 },
          ]
        }
        autofs::mapping { 'dataA':
          mapfile => '/etc/auto.data',
          key     => 'dataA',
          options => 'ro',
          fs      => 'fs.net:/export/dataA',
          order   => 10,
        }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.data') do
      it 'exists and belongs to root' do
        expect(subject).to exist
        expect(subject).to be_owned_by 'root'
        expect(subject).to be_grouped_into 'root'
      end

      its(:content) do
        is_expected.to match %r{^\s*dataA\s+-ro\s+fs.net:/export/dataA\s*\n\s*dataB\s+-rw,noexec\s+fs.net:/export/dataB\s*$}
      end
    end
  end
end
