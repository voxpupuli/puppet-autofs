require 'spec_helper'
describe 'autofs::mount', type: :define do
  on_supported_os.each do |os, facts|
    let(:pre_condition) { 'include autofs' }

    case facts[:os]['family']
    when 'AIX'
      group = 'system'
      master_map_file = '/etc/auto_master'
    when 'Solaris'
      group = 'root'
      master_map_file = '/etc/auto_master'
    else
      group = 'root'
      master_map_file = '/etc/auto.master'
    end

    context "on #{os}" do
      let(:title) { 'auto.home' }
      let(:facts) do
        facts.merge(concat_basedir: '/etc')
      end

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
          is_expected.not_to contain_file('/home')
          is_expected.to contain_concat('/etc/auto.master').
            with(group: group)
          is_expected.to contain_concat__fragment('autofs::fragment preamble /home /etc/auto.home').with('target' => '/etc/auto.master')
          is_expected.to have_concat_resource_count(1)
          is_expected.to have_autofs__map_resource_count(0)
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
          is_expected.to contain_concat__fragment('autofs::fragment preamble /smb program:/etc/auto.smb')
          is_expected.not_to contain_file('/etc/auto.smb')
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
          is_expected.to contain_concat__fragment('autofs::fragment preamble /- /etc/auto.home')
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
          is_expected.to compile.and_raise_error(%r{parameter 'mount' expects a Stdlib::Absolutepath|parameter 'mount' expects a match for})
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
          is_expected.to have_autofs__map_resource_count(0)
          is_expected.to contain_concat(master_map_file).
            with(group: group)
          is_expected.to contain_concat__fragment('autofs::fragment preamble /data /etc/auto.data').
            with_target(master_map_file)
          is_expected.not_to contain_concat('/etc/auto.data').
            with(group: group)
          is_expected.not_to contain_file('/data')
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
          is_expected.to contain_concat(master_map_file).
            with(group: group)
          is_expected.to contain_concat__fragment('autofs::fragment preamble /net -hosts').
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
          is_expected.to compile
          is_expected.to contain_concat(master_map_file).
            with(group: group)
          is_expected.to contain_concat__fragment('autofs::fragment preamble /data file,sun:/etc/auto.data').
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
          is_expected.to compile
          is_expected.to contain_concat(master_map_file).
            with(group: group)
          is_expected.to contain_concat__fragment('autofs::fragment preamble /mnt yp:mnt.map').
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
        let(:title) { '/data' }
        let(:params) do
          {
            ensure: 'absent',
            mapfile: '/etc/auto.data'
          }
        end

        it do
          is_expected.to contain_file_line("#{master_map_file}::/data_/etc/auto.data").with(
            ensure: 'absent',
            path: master_map_file,
            match: '^\\s*/data\\s+/etc/auto.data\\s'
          )
          is_expected.to contain_concat(master_map_file).
            with(group: group)
          is_expected.to have_concat__fragment_resource_count(0)
          is_expected.to have_autofs__map_resource_count(0)
        end
      end
    end
  end
end
