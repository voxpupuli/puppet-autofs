# frozen_string_literal: true

require 'spec_helper'

describe 'autofs::mapping', type: :define do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:title) { 'data' }

      context 'with no options' do
        let(:params) do
          {
            mapfile: '/mnt/auto.data',
            key: 'data',
            fs: 'storage.host.net:/exports/data',
          }
        end

        it do
          expect(subject).to compile
          expect(subject).not_to contain_class('autofs')
          expect(subject).to have_concat_resource_count(0)
          expect(subject).to have_concat__fragment_resource_count(1)
          expect(subject).to contain_concat__fragment('autofs::mapping/data')
            .with(target: '/mnt/auto.data', content: "data		storage.host.net:/exports/data\n")
        end
      end

      context 'with order' do
        let(:params) do
          {
            ensure: 'present',
            mapfile: '/mnt/auto.data',
            key: 'data',
            fs: 'storage.host.net:/exports/data',
            order: 20,
          }
        end

        it do
          expect(subject).to compile
          expect(subject).not_to contain_class('autofs')
          expect(subject).to have_concat_resource_count(0)
          expect(subject).to have_concat__fragment_resource_count(1)
          expect(subject).to contain_concat__fragment('autofs::mapping/data')
            .with(target: '/mnt/auto.data', order: 20)
        end
      end

      context 'with ensure present' do
        let(:params) do
          {
            ensure: 'present',
            mapfile: '/mnt/auto.data',
            key: 'data',
            fs: 'storage.host.net:/exports/data',
          }
        end

        it do
          expect(subject).to compile
          expect(subject).not_to contain_class('autofs')
          expect(subject).to have_concat_resource_count(0)
          expect(subject).to have_concat__fragment_resource_count(1)
          expect(subject).to contain_concat__fragment('autofs::mapping/data')
            .with(target: '/mnt/auto.data', content: "data		storage.host.net:/exports/data\n")
        end
      end

      context 'with ensure absent' do
        let(:params) do
          {
            ensure: 'absent',
            mapfile: '/mnt/auto.data',
            key: 'data',
            fs: 'storage.host.net:/exports/data',
          }
        end

        it do
          expect(subject).to compile
          expect(subject).not_to contain_class('autofs')
          expect(subject).to have_concat_resource_count(0)
          expect(subject).to have_concat__fragment_resource_count(0)
        end
      end

      context 'with options string' do
        let(:params) do
          {
            mapfile: '/mnt/auto.data',
            key: 'data',
            options: 'rw,sync,nosuid',
            fs: 'storage.host.net:/exports/data',
          }
        end

        it do
          expect(subject).to compile
          expect(subject).not_to contain_class('autofs')
          expect(subject).to have_concat_resource_count(0)
          expect(subject).to have_concat__fragment_resource_count(1)
          expect(subject).to contain_concat__fragment('autofs::mapping/data')
            .with(target: '/mnt/auto.data', content: "data	-rw,sync,nosuid	storage.host.net:/exports/data\n")
        end
      end

      context 'with empty options' do
        let(:params) do
          {
            mapfile: '/mnt/auto.data',
            key: 'data',
            options: [],
            fs: 'storage.host.net:/exports/data',
          }
        end

        it do
          expect(subject).to compile
          expect(subject).not_to contain_class('autofs')
          expect(subject).to have_concat_resource_count(0)
          expect(subject).to have_concat__fragment_resource_count(1)
          expect(subject).to contain_concat__fragment('autofs::mapping/data')
            .with(target: '/mnt/auto.data', content: "data		storage.host.net:/exports/data\n")
        end
      end

      context 'with options array' do
        let(:params) do
          {
            mapfile: '/mnt/auto.data',
            key: 'data',
            options: %w[rw sync nosuid],
            fs: 'storage.host.net:/exports/data',
          }
        end

        it do
          expect(subject).to compile
          expect(subject).not_to contain_class('autofs')
          expect(subject).to have_concat_resource_count(0)
          expect(subject).to have_concat__fragment_resource_count(1)
          expect(subject).to contain_concat__fragment('autofs::mapping/data')
            .with(target: '/mnt/auto.data', content: "data	-rw,sync,nosuid	storage.host.net:/exports/data\n")
        end
      end

      context 'with replicated filesystems' do
        let(:params) do
          {
            mapfile: '/mnt/auto.data',
            key: 'data',
            options: 'rw',
            fs: [
              'storage.host.net:/exports/data',
              'backup.host.net:/exports/data',
            ],
          }
        end

        it do
          expect(subject).to compile
          expect(subject).not_to contain_class('autofs')
          expect(subject).to have_concat_resource_count(0)
          expect(subject).to have_concat__fragment_resource_count(1)
          expect(subject).to contain_concat__fragment('autofs::mapping/data')
            .with(target: '/mnt/auto.data', content: "data	-rw	storage.host.net:/exports/data backup.host.net:/exports/data\n")
        end
      end

      context 'with spaces in path' do
        let(:params) do
          {
            mapfile: '/mnt/auto.data',
            key: %(/scary/don't fear "quotes" and spaces),
            options: 'rw',
            fs: %(storage.host.net:/exports/data/don't fear "quotes" and spaces nor $do\\\\ars),
          }
        end

        it do
          expect(subject).to compile
          expect(subject).not_to contain_class('autofs')
          expect(subject).to have_concat_resource_count(0)
          expect(subject).to have_concat__fragment_resource_count(1)
          expect(subject).to contain_concat__fragment('autofs::mapping/data')
            .with(target: '/mnt/auto.data', content: %("/scary/don't fear \\"quotes\\" and spaces"\t-rw\t"storage.host.net:/exports/data/don't fear \\"quotes\\" and spaces nor $do\\\\ars"\n))
        end
      end

      context 'with multi-mount entries' do
        let(:params) do
          {
            mapfile: '/mnt/auto.data',
            key: 'data',
            options: 'rw',
            mounts: [
              { 'mountpoint' => '/', 'fs' => 'nfs1:/d1' },
              { 'mountpoint' => '/docs', 'options' => 'ro', 'fs' => 'nfs1:/d2' },
            ],
          }
        end

        it do
          expect(subject).to compile
          expect(subject).not_to contain_class('autofs')
          expect(subject).to have_concat__fragment_resource_count(1)
          expect(subject).to contain_concat__fragment('autofs::mapping/data')
            .with(target: '/mnt/auto.data', content: "data	-rw	/ nfs1:/d1 /docs -ro nfs1:/d2\n")
        end
      end

      context 'with an omitted base offset' do
        let(:params) do
          {
            mapfile: '/mnt/auto.data',
            key: 'data',
            mounts: [
              { 'fs' => 'nfs1:/d1' },
              { 'mountpoint' => '/docs', 'fs' => 'nfs1:/d2' },
            ],
          }
        end

        it do
          expect(subject).to compile
          expect(subject).to contain_concat__fragment('autofs::mapping/data')
            .with(target: '/mnt/auto.data', content: "data		nfs1:/d1 /docs nfs1:/d2\n")
        end
      end

      context 'with both fs and mounts is an error' do
        let(:params) do
          {
            mapfile: '/mnt/auto.data',
            key: 'data',
            fs: 'nfs1:/d1',
            mounts: [{ 'mountpoint' => '/', 'fs' => 'nfs1:/d1' }],
          }
        end

        it { expect(subject).to compile.and_raise_error(%r{specify either fs or mounts, not both}) }
      end

      context 'without fs or mounts is an error' do
        let(:params) { { mapfile: '/mnt/auto.data', key: 'data' } }

        it { expect(subject).to compile.and_raise_error(%r{specify either fs or mounts}) }
      end
    end
  end
end
