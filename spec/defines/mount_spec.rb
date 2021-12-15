# frozen_string_literal: true

require 'spec_helper'
describe 'autofs::mount', type: :define do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:title) { 'auto.home' }
      let(:pre_condition) { 'include autofs' }
      let(:group) { facts[:os]['family'] == 'AIX' ? 'system' : 'root' }
      let(:master_map_file) { %w[AIX Solaris].include?(facts[:os]['family']) ? '/etc/auto_master' : '/etc/auto.master' }
      let(:facts) { os_facts }

      # rubocop:disable RSpec/MultipleMemoizedHelpers
      context 'with default parameters' do
        let(:params) do
          {
            mount: '/home',
            mapfile: '/etc/auto.home',
            options: '--timeout=120',
            order: 1,
            master: '/etc/auto.master'
          }
        end

        it do
          expect(subject).not_to contain_file('/home')
          expect(subject).to contain_concat('/etc/auto.master').
            with(group: group)
          expect(subject).to contain_concat__fragment('autofs::fragment preamble /home /etc/auto.home').with('target' => '/etc/auto.master')
          expect(subject).to have_concat_resource_count(1)
          expect(subject).to have_autofs__map_resource_count(0)
        end
      end

      context 'with unmanged maptype specified' do
        # This is no longer meaningfully distinct from the previous example
        let(:params) do
          {
            mount: '/smb',
            mapfile: 'program:/etc/auto.smb',
            options: '--timeout=120',
            order: 2
          }
        end

        it do
          expect(subject).to contain_concat__fragment('autofs::fragment preamble /smb program:/etc/auto.smb')
          expect(subject).not_to contain_file('/etc/auto.smb')
        end
      end

      context 'with direct map' do
        let(:params) do
          {
            mount: '/-',
            mapfile: '/etc/auto.home',
            options: '--timeout=120',
            order: 1
          }
        end

        it do
          expect(subject).to contain_concat__fragment('autofs::fragment preamble /- /etc/auto.home')
        end
      end

      context 'without mapfile' do
        let(:params) do
          {
            mount: '/net',
            options: '-host',
            use_dir: false,
            order: 1
          }
        end

        it { is_expected.to compile.and_raise_error(%r{.*}) }
      end

      context 'with indirect map and invalid title' do
        let(:params) do
          {
            mapfile: '/etc/auto.home',
            options: '--timeout=120',
            order: 1
          }
        end

        it 'is expected to fail' do
          expect(subject).to compile.and_raise_error(%r{parameter 'mount' expects a Stdlib::Absolutepath|parameter 'mount' expects a match for})
        end
      end

      context 'with indirect map and valid title' do
        let(:title) { '/data' }
        let(:params) do
          {
            mapfile: '/etc/auto.data',
            options: '--timeout=360',
            order: 1
          }
        end

        it do
          expect(subject).to have_autofs__map_resource_count(0)
          expect(subject).to contain_concat(master_map_file).
            with(group: group)
          expect(subject).to contain_concat__fragment('autofs::fragment preamble /data /etc/auto.data').
            with_target(master_map_file)
          expect(subject).not_to contain_concat('/etc/auto.data').
            with(group: group)
          expect(subject).not_to contain_file('/data')
        end
      end

      context 'with special -hosts map' do
        let(:title) { 'auto.NET' }
        let(:params) do
          {
            mount: '/net',
            mapfile: '-hosts'
          }
        end

        it do
          expect(subject).to contain_concat(master_map_file).
            with(group: group)
          expect(subject).to contain_concat__fragment('autofs::fragment preamble /net -hosts').
            with_target(master_map_file)
        end
      end

      context 'with map format option' do
        let(:title) { '/data' }
        let(:params) do
          {
            mapfile: 'file,sun:/etc/auto.data'
          }
        end

        it do
          expect(subject).to compile
          expect(subject).to contain_concat(master_map_file).
            with(group: group)
          expect(subject).to contain_concat__fragment('autofs::fragment preamble /data file,sun:/etc/auto.data').
            with_target(master_map_file).
            with_content(%r{\A\s*/data\s+file,sun:/etc/auto.data\s*$})
        end
      end

      context 'with map type and no leading slash' do
        # this example is drawn directly from the Linux auto.master(5) manual page
        let(:title) { '/mnt' }
        let(:params) do
          {
            mapfile: 'yp:mnt.map'
          }
        end

        it do
          expect(subject).to compile
          expect(subject).to contain_concat(master_map_file).
            with(group: group)
          expect(subject).to contain_concat__fragment('autofs::fragment preamble /mnt yp:mnt.map').
            with_target(master_map_file).
            with_content(%r{\A\s*/mnt\s+yp:mnt.map\s*$})
        end
      end

      context 'with relative map file' do
        # This one expects compilation to fail
        let(:title) { '/data' }
        let(:params) do
          {
            mapfile: 'etc/auto.data'
          }
        end

        it { is_expected.to compile.and_raise_error(%r{.*}) }
      end

      context 'with ensure set to absent' do
        # rubocop:enable RSpec/MultipleMemoizedHelpers
        let(:title) { '/data' }
        let(:params) do
          {
            ensure: 'absent',
            mapfile: '/etc/auto.data'
          }
        end

        it do
          expect(subject).to contain_file_line("#{master_map_file}::/data_/etc/auto.data").with(
            ensure: 'absent',
            path: master_map_file,
            match: '^\\s*/data\\s+/etc/auto.data\\s'
          )
          expect(subject).to contain_concat(master_map_file).
            with(group: group)
          expect(subject).to have_concat__fragment_resource_count(0)
          expect(subject).to have_autofs__map_resource_count(0)
        end
      end
    end
  end
end
