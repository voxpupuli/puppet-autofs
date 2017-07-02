require 'spec_helper'
describe 'autofs::mount', type: :define do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:title) { 'auto.home' }

      let(:facts) do
        facts.merge(concat_basedir: '/etc')
      end

      let(:params) do
        {
          mount: '/home',
          mapfile: '/etc/auto.home',
          mapcontents: %w[test foo bar],
          options: '--timeout=120',
          order: 1,
          master: '/etc/auto.master'
        }
      end

      context 'with default parameters' do
        it do
          is_expected.to contain_concat('/etc/auto.master')
          is_expected.to contain_concat__fragment('autofs::fragment preamble /home /etc/auto.home').with('target' => '/etc/auto.master')
        end

        it do
          is_expected.to contain_concat('/etc/auto.home').with(
            'ensure' => 'present',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0644'
          )
          is_expected.to contain_concat__fragment('/etc/auto.home_auto.home_entries').with(
            'target' => '/etc/auto.home'
          )
          is_expected.to contain_autofs__map('auto.home')
        end
      end

      context 'with unmanged mapfile' do
        let(:params) do
          {
            mount: '/smb',
            mapfile: '/etc/auto.smb',
            mapfile_manage: false,
            options: '--timeout=120',
            order: 2,
            direct: false
          }
        end

        it do
          is_expected.not_to contain_file('/etc/auto.smb')
          is_expected.to contain_concat__fragment('autofs::fragment preamble /smb /etc/auto.smb')
        end
      end

      context 'with unmanged maptype specified' do
        let(:params) do
          {
            mount: '/smb',
            mapfile: 'program:/etc/auto.smb',
            mapfile_manage: false,
            options: '--timeout=120',
            order: 2,
            direct: false
          }
        end

        it do
          is_expected.to contain_concat__fragment('autofs::fragment preamble /smb program:/etc/auto.smb')
          is_expected.not_to contain_file('/etc/auto.smb')
        end
      end

      context 'with manged maptype' do
        let(:params) do
          {
            mount: '/smb',
            mapfile: 'program:/etc/auto.smb',
            mapfile_manage: true,
            options: '--timeout=120',
            order: 2,
            direct: false
          }
        end

        it 'is expected to fail' do
          is_expected.to compile.and_raise_error(%r{Parameter 'mapfile_manage' must be false for complicated})
        end
      end

      context 'with indirect map' do
        let(:params) do
          {
            mount: '/home',
            mapfile: '/etc/auto.home',
            mapcontents: %w[test foo bar],
            options: '--timeout=120',
            order: 1,
            direct: false
          }
        end

        it do
          is_expected.not_to contain_file('/home').with('ensure' => 'directory')
        end
      end

      context 'with direct map' do
        let(:params) do
          {
            mount: '/-',
            mapfile: '/etc/auto.home',
            mapcontents: ['/home /test', '/home /foo', '/home /bar'],
            options: '--timeout=120',
            order: 1,
            direct: true
          }
        end

        it do
          is_expected.to contain_concat__fragment('autofs::fragment preamble /- /etc/auto.home')
        end
      end

      context 'with EL7 directory' do
        let(:params) do
          {
            name: 'home',
            mount: '/home',
            mapfile: '/etc/auto.home',
            mapcontents: %w[test foo bar],
            options: '--timeout=120',
            order: 1,
            map_dir: '/etc/auto.master.d',
            use_dir: true
          }
        end

        it do
          is_expected.to contain_concat__fragment('autofs::fragment preamble map directory')
        end

        it do
          is_expected.to contain_file('/etc/auto.master.d').with(
            'ensure' => 'directory',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0755'
          )

          is_expected.to contain_file('/etc/auto.master.d/home.autofs').with(
            'ensure' => 'present',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0644'
          )

          is_expected.to contain_concat('/etc/auto.home').with(
            'ensure' => 'present',
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0644'
          )
        end
      end

      context 'with executable map' do
        let(:params) do
          {
            mount: '/home',
            mapfile: '/etc/auto.home',
            mapcontents: %w[test foo bar],
            options: '--timeout=120',
            order: 1,
            execute: true
          }
        end

        it do
          is_expected.to contain_concat('/etc/auto.home').with('mode' => '0755')
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

        it do
          is_expected.not_to contain_concat('/etc/auto.-host')
          is_expected.to contain_concat__fragment('autofs::fragment preamble /net ').with_content(
            %r{/net -host\n}
          )
        end
      end

      context 'with indirect map and invalid title' do
        let(:params) do
          {
            mapfile: '/etc/auto.home',
            mapcontents: %w[test foo bar],
            options: '--timeout=120',
            order: 1,
            direct: false
          }
        end

        it 'is expected to fail' do
          is_expected.to compile.and_raise_error(%r{parameter 'mount' expects a match for})
        end
      end

      context 'with indirect map and valid title' do
        let(:title) { '/data' }
        let(:params) do
          {
            mapfile: '/etc/auto.data',
            mapcontents: %w[dataA dataB dataC],
            options: '--timeout=360',
            order: 1,
            direct: false
          }
        end

        it do
          is_expected.to contain_autofs__map('/data')
          is_expected.to contain_concat('/etc/auto.master')
          is_expected.to contain_concat__fragment('autofs::fragment preamble /data /etc/auto.data').with_target('/etc/auto.master')
          is_expected.to contain_concat('/etc/auto.data')
          is_expected.to contain_concat__fragment('/etc/auto.data_/data_entries').with_target('/etc/auto.data')
          is_expected.not_to contain_file('/data').with('ensure' => 'directory')
        end
      end
    end
  end
end
