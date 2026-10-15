# frozen_string_literal: true

require 'spec_helper'
describe 'autofs::mount', type: :define do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:title) { 'auto.home' }
      let(:pre_condition) { 'include autofs' }
      let(:facts) { os_facts }

      # Plain helpers derived from facts; kept out of `let` to avoid
      # bloating the memoized helper count per example group.
      def group
        case facts['os']['family']
        when 'AIX' then 'system'
        when 'FreeBSD' then 'wheel'
        else 'root'
        end
      end

      def master_map_file
        %w[AIX FreeBSD Solaris].include?(facts['os']['family']) ? '/etc/auto_master' : '/etc/auto.master'
      end

      context 'with default parameters' do
        let(:title) { 'auto.home' }
        let(:params) do
          {
            mount: '/home',
            mapfile: '/etc/auto.home',
            options: '--timeout=120',
            order: 1,
            master: '/etc/auto.master',
          }
        end

        it do
          expect(subject).not_to contain_file('/home')
          # The master map entry is delegated to autofs::add_master_entry.
          expect(subject).to contain_autofs__add_master_entry('autofs::mount auto.home')
            .with(ensure: 'present', master: '/etc/auto.master', order: 1)
            .with_entry('/home /etc/auto.home --timeout=120')
          expect(subject).to contain_concat__fragment('autofs::add_master_entry autofs::mount auto.home')
            .with(
              'target' => '/etc/auto.master',
              'content' => "/home /etc/auto.home --timeout=120\n",
            )
          expect(subject).to have_concat__fragment_resource_count(1)
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
            order: 2,
          }
        end

        it do
          expect(subject).to contain_concat__fragment('autofs::add_master_entry autofs::mount auto.home')
            .with('content' => "/smb program:/etc/auto.smb --timeout=120\n")
          expect(subject).not_to contain_file('/etc/auto.smb')
        end
      end

      context 'with direct map' do
        let(:params) do
          {
            mount: '/-',
            mapfile: '/etc/auto.home',
            options: '--timeout=120',
            order: 1,
          }
        end

        it do
          expect(subject).to contain_concat__fragment('autofs::add_master_entry autofs::mount auto.home')
            .with('content' => "/- /etc/auto.home --timeout=120\n")
        end
      end

      context 'without mapfile' do
        let(:params) do
          {
            mount: '/net',
            options: '-host',
            use_dir: false,
            order: 1,
          }
        end

        it { is_expected.to compile.and_raise_error(%r{.*}) }
      end

      context 'with indirect map and invalid title' do
        let(:params) do
          {
            mapfile: '/etc/auto.home',
            options: '--timeout=120',
            order: 1,
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
            order: 1,
          }
        end

        it do
          expect(subject).to have_autofs__map_resource_count(0)
          expect(subject).to contain_autofs__add_master_entry('autofs::mount /data')
            .with_master(master_map_file)
            .with_entry(%r{\A/data /etc/auto\.data --timeout=360\z})
          expect(subject).to contain_concat(master_map_file)
            .with(group: group)
          expect(subject).to contain_concat__fragment('autofs::add_master_entry autofs::mount /data')
            .with_target(master_map_file)
            .with_content(%r{\A\s*/data\s+/etc/auto.data --timeout=360\s*\z})
          expect(subject).not_to contain_concat('/etc/auto.data')
            .with(group: group)
          expect(subject).not_to contain_file('/data')
        end
      end

      context 'with special -hosts map' do
        let(:title) { 'auto.NET' }
        let(:params) do
          {
            mount: '/net',
            mapfile: '-hosts',
          }
        end

        it do
          expect(subject).to contain_autofs__add_master_entry('autofs::mount auto.NET')
            .with_entry(%r{\A/net -hosts\s*\z})
          expect(subject).to contain_concat(master_map_file)
            .with(group: group)
          expect(subject).to contain_concat__fragment('autofs::add_master_entry autofs::mount auto.NET')
            .with_target(master_map_file)
            .with_content(%r{\A\s*/net\s+-hosts\s*$})
        end
      end

      context 'with map format option' do
        let(:title) { '/data' }
        let(:params) do
          {
            mapfile: 'file,sun:/etc/auto.data',
          }
        end

        it do
          expect(subject).to compile
          expect(subject).to contain_concat(master_map_file)
            .with(group: group)
          expect(subject).to contain_concat__fragment('autofs::add_master_entry autofs::mount /data')
            .with_target(master_map_file)
            .with_content(%r{\A\s*/data\s+file,sun:/etc/auto.data\s*$})
        end
      end

      context 'with map type and no leading slash' do
        # this example is drawn directly from the Linux auto.master(5) manual page
        let(:title) { '/mnt' }
        let(:params) do
          {
            mapfile: 'yp:mnt.map',
          }
        end

        it do
          expect(subject).to compile
          expect(subject).to contain_autofs__add_master_entry('autofs::mount /mnt')
            .with_entry(%r{\A/mnt yp:mnt\.map\s*\z})
          expect(subject).to contain_concat(master_map_file)
            .with(group: group)
          expect(subject).to contain_concat__fragment('autofs::add_master_entry autofs::mount /mnt')
            .with_target(master_map_file)
            .with_content(%r{\A\s*/mnt\s+yp:mnt.map\s*$})
        end
      end

      context 'with relative map file' do
        # This one expects compilation to fail
        let(:title) { '/data' }
        let(:params) do
          {
            mapfile: 'etc/auto.data',
          }
        end

        it { is_expected.to compile.and_raise_error(%r{.*}) }
      end

      context 'with manage_auto_master disabled and a direct master map entry' do
        let(:pre_condition) { 'class { "autofs": manage_auto_master => false }' }
        let(:params) do
          {
            mount: '/home',
            mapfile: '/etc/auto.home',
            options: '--timeout=120',
          }
        end

        it { is_expected.to compile.and_raise_error(%r{manage_auto_master}) }
      end

      context 'with manage_auto_master disabled and use_dir' do
        let(:pre_condition) { 'class { "autofs": manage_auto_master => false }' }
        let(:params) do
          {
            mount: '/home',
            mapfile: '/etc/auto.home',
            options: '--timeout=120',
            use_dir: true,
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).not_to contain_concat(master_map_file)
          expect(subject).not_to contain_concat__fragment('autofs::add_master_entry /etc/auto.master.d')
          # ensure_dir is opt-in; without it the module leaves the drop-in
          # directory alone even though it manages the drop-in files.
          expect(subject).not_to contain_file('/etc/auto.master.d')
          expect(subject).to contain_file('/etc/auto.master.d/auto.home.autofs')
            .with_content(%r{\A/home /etc/auto.home --timeout=120\s*\z})
        end
      end

      context 'with manage_auto_master disabled, use_dir and ensure_dir' do
        let(:pre_condition) { 'class { "autofs": manage_auto_master => false }' }
        let(:params) do
          {
            mount: '/home',
            mapfile: '/etc/auto.home',
            options: '--timeout=120',
            use_dir: true,
            ensure_dir: true,
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_autofs__mapdir('autofs::mount auto.home')
            .with_path('/etc/auto.master.d')
          expect(subject).to contain_file('/etc/auto.master.d')
            .with(ensure: 'directory', owner: 'root', group: group)
          expect(subject).to contain_file('/etc/auto.master.d/auto.home.autofs')
            .that_requires('Autofs::Mapdir[autofs::mount auto.home]')
            .that_requires('File[/etc/auto.master.d]')
        end
      end

      context 'with use_dir and ensure_dir' do
        let(:title) { 'confdir' }
        let(:params) do
          {
            mount: '/mnt/confdir',
            mapfile: '/etc/auto.confdir',
            options: '--timeout=120',
            use_dir: true,
            ensure_dir: true,
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_autofs__add_master_entry('/etc/auto.master.d')
            .with(entry: '+dir:/etc/auto.master.d', master: master_map_file, ensure_dir: true)
          expect(subject).to contain_file('/etc/auto.master.d')
            .with(ensure: 'directory', owner: 'root', group: group)
          expect(subject).to contain_concat__fragment('autofs::add_master_entry /etc/auto.master.d')
            .that_requires('File[/etc/auto.master.d]')
          expect(subject).to contain_file('/etc/auto.master.d/confdir.autofs')
            .that_requires('Concat::Fragment[autofs::add_master_entry /etc/auto.master.d]')
        end
      end

      context 'with manage_auto_master enabled and use_dir' do
        let(:pre_condition) { 'class { "autofs": manage_auto_master => true }' }
        let(:title) { 'confdir' }
        let(:params) do
          {
            mount: '/mnt/confdir',
            mapfile: '/etc/auto.confdir',
            options: '--timeout=120',
            use_dir: true,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat(master_map_file) }

        it {
          is_expected.to contain_concat__fragment('autofs::add_master_entry /etc/auto.master.d')
            .with(target: master_map_file)
            .with_content(%r{\A\+dir:/etc/auto.master.d\s*\z})
        }

        it {
          is_expected.to contain_file('/etc/auto.master.d/confdir.autofs')
            .with_content(%r{\A/mnt/confdir /etc/auto.confdir --timeout=120\s*\z})
        }
      end

      context 'with ensure set to absent' do
        let(:title) { '/data' }
        let(:params) do
          {
            ensure: 'absent',
            mapfile: '/etc/auto.data',
          }
        end

        it do
          # The master map is fully concat-managed, so removal means the
          # concat fragment is simply absent; there is no File_line anymore.
          expect(subject).not_to contain_file_line("#{master_map_file}::autofs::mount /data_/etc/auto.master.d")
          expect(subject).to contain_concat(master_map_file)
            .with(group: group)
          expect(subject).to have_concat__fragment_resource_count(0)
          expect(subject).to have_autofs__map_resource_count(0)
        end
      end
    end
  end
end
