require 'spec_helper'

describe 'autofs::mapfile', type: :define do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context 'with default parameters' do
        let(:title) { '/etc/auto.data' }

        it do
          is_expected.to compile
          is_expected.to contain_class('autofs')
          is_expected.to contain_concat('/etc/auto.data').
            with(ensure: 'present', replace: true)
        end
      end

      context 'with explicit path' do
        let(:title) { 'data' }
        let(:params) do
          { path: '/etc/autofs/data' } # an unconventional path
        end

        it do
          is_expected.to compile
          is_expected.to contain_class('autofs')
          is_expected.to contain_concat('/etc/autofs/data').
            with(ensure: 'present', replace: true)
        end
      end

      context 'without replacement' do
        let(:title) { '/etc/auto.data' }
        let(:params) { { replace: false } }

        it do
          is_expected.to compile
          is_expected.to contain_class('autofs')
          is_expected.to contain_concat('/etc/auto.data').
            with(ensure: 'present', replace: false)
        end
      end

      context 'without ensuring absence' do
        let(:title) { '/etc/auto.data' }
        let(:params) { { ensure: 'absent' } }

        it do
          is_expected.to compile
          is_expected.to contain_class('autofs')
          is_expected.to contain_concat('/etc/auto.data').
            with(ensure: 'absent')
        end
      end

      context 'with mappings' do
        let(:title) { '/etc/auto.data' }
        let(:params) do
          {
            mappings: [
              { key: 'example1', fs: 'data.com:/export/example1' },
              { key: 'example2', options: 'rw', fs: 'data.com:/export/example2' },
              { key: 'example3', options: %w[rw noexec], fs: 'data.com:/export/example3' }
            ]
          }
        end

        it do
          is_expected.to compile
          is_expected.to contain_class('autofs')
          is_expected.to contain_concat('/etc/auto.data').
            with(ensure: 'present')
          is_expected.to have_autofs__mapping_resource_count(3)
          is_expected.to contain_autofs__mapping('/etc/auto.data:example1').
            with(mapfile: '/etc/auto.data', key: 'example1', fs: 'data.com:/export/example1')
          is_expected.to contain_autofs__mapping('/etc/auto.data:example2').
            with(mapfile: '/etc/auto.data', key: 'example2', options: 'rw', fs: 'data.com:/export/example2')
          is_expected.to contain_autofs__mapping('/etc/auto.data:example3').
            with(mapfile: '/etc/auto.data', key: 'example3', options: %w[rw noexec], fs: 'data.com:/export/example3')
        end
      end
    end
  end
end
