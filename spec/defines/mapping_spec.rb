require 'spec_helper'

describe 'autofs::mapping', type: :define do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'data' }

      context 'with no options' do
        let(:params) do
          {
            mapfile: '/mnt/auto.data',
            key: 'data',
            fs: 'storage.host.net:/exports/data'
          }
        end

        it do
          is_expected.to compile
          is_expected.not_to contain_class('autofs')
          is_expected.to have_concat_resource_count(0)
          is_expected.to have_concat__fragment_resource_count(1)
          is_expected.to contain_concat__fragment('autofs::mapping/data').
            with(target: '/mnt/auto.data', content: "data		storage.host.net:/exports/data\n")
        end
      end

      context 'with order' do
        let(:params) do
          {
            ensure: 'present',
            mapfile: '/mnt/auto.data',
            key: 'data',
            fs: 'storage.host.net:/exports/data',
            order: 20
          }
        end

        it do
          is_expected.to compile
          is_expected.not_to contain_class('autofs')
          is_expected.to have_concat_resource_count(0)
          is_expected.to have_concat__fragment_resource_count(1)
          is_expected.to contain_concat__fragment('autofs::mapping/data').
            with(target: '/mnt/auto.data', order: 20)
        end
      end

      context 'with ensure present' do
        let(:params) do
          {
            ensure: 'present',
            mapfile: '/mnt/auto.data',
            key: 'data',
            fs: 'storage.host.net:/exports/data'
          }
        end

        it do
          is_expected.to compile
          is_expected.not_to contain_class('autofs')
          is_expected.to have_concat_resource_count(0)
          is_expected.to have_concat__fragment_resource_count(1)
          is_expected.to contain_concat__fragment('autofs::mapping/data').
            with(target: '/mnt/auto.data', content: "data		storage.host.net:/exports/data\n")
        end
      end

      context 'with ensure absent' do
        let(:params) do
          {
            ensure: 'absent',
            mapfile: '/mnt/auto.data',
            key: 'data',
            fs: 'storage.host.net:/exports/data'
          }
        end

        it do
          is_expected.to compile
          is_expected.not_to contain_class('autofs')
          is_expected.to have_concat_resource_count(0)
          is_expected.to have_concat__fragment_resource_count(0)
        end
      end

      context 'with options string' do
        let(:params) do
          {
            mapfile: '/mnt/auto.data',
            key: 'data',
            options: 'rw,sync,nosuid',
            fs: 'storage.host.net:/exports/data'
          }
        end

        it do
          is_expected.to compile
          is_expected.not_to contain_class('autofs')
          is_expected.to have_concat_resource_count(0)
          is_expected.to have_concat__fragment_resource_count(1)
          is_expected.to contain_concat__fragment('autofs::mapping/data').
            with(target: '/mnt/auto.data', content: "data	-rw,sync,nosuid	storage.host.net:/exports/data\n")
        end
      end

      context 'with empty options' do
        let(:params) do
          {
            mapfile: '/mnt/auto.data',
            key: 'data',
            options: [],
            fs: 'storage.host.net:/exports/data'
          }
        end

        it do
          is_expected.to compile
          is_expected.not_to contain_class('autofs')
          is_expected.to have_concat_resource_count(0)
          is_expected.to have_concat__fragment_resource_count(1)
          is_expected.to contain_concat__fragment('autofs::mapping/data').
            with(target: '/mnt/auto.data', content: "data		storage.host.net:/exports/data\n")
        end
      end

      context 'with options array' do
        let(:params) do
          {
            mapfile: '/mnt/auto.data',
            key: 'data',
            options: %w[rw sync nosuid],
            fs: 'storage.host.net:/exports/data'
          }
        end

        it do
          is_expected.to compile
          is_expected.not_to contain_class('autofs')
          is_expected.to have_concat_resource_count(0)
          is_expected.to have_concat__fragment_resource_count(1)
          is_expected.to contain_concat__fragment('autofs::mapping/data').
            with(target: '/mnt/auto.data', content: "data	-rw,sync,nosuid	storage.host.net:/exports/data\n")
        end
      end

      context 'with replicated filesystems' do
        let(:params) do
          {
            mapfile: '/mnt/auto.data',
            key: 'data',
            options: 'rw',
            fs: 'storage.host.net:/exports/data backup.host.net:/exports/data'
          }
        end

        it do
          is_expected.to compile
          is_expected.not_to contain_class('autofs')
          is_expected.to have_concat_resource_count(0)
          is_expected.to have_concat__fragment_resource_count(1)
          is_expected.to contain_concat__fragment('autofs::mapping/data').
            with(target: '/mnt/auto.data', content: "data	-rw	storage.host.net:/exports/data backup.host.net:/exports/data\n")
        end
      end
    end
  end
end
