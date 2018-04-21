require 'spec_helper_acceptance'

describe 'autofs::mount -hosts test' do
  context 'basic special -hosts test' do
    it 'applies' do
      pp = <<-MANIFEST
        class { 'autofs': }
        autofs::mount { 'auto.net':
          mount          => '/net',
          mapfile        => '-hosts',
        }
      MANIFEST

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.master') do
      it 'exists and has content' do
        is_expected.to exist
        is_expected.to be_owned_by 'root'
        is_expected.to be_grouped_into 'root'
      end

      its(:content) { is_expected.to match(%r{^\s*/net\s+-hosts\s*$}) }
    end
  end
end
