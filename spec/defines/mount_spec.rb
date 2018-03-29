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
            'group'  => group,
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

      [true, false].each do |execute|
        context "with EL7 directory and #{execute ? '' : 'non-'}executable map" do
          let(:params) do
            {
              name: 'home',
              mount: '/home',
              mapfile: '/etc/auto.home',
              mapcontents: %w[test foo bar],
              options: '--timeout=120',
              order: 1,
              map_dir: '/etc/auto.master.d',
              use_dir: true,
              execute: execute
            }
          end

          it do
            is_expected.to contain_concat__fragment('autofs::fragment preamble map directory')
          end

          it do
            is_expected.to contain_file('/etc/auto.master.d').with(
              'ensure' => 'directory',
              'owner'  => 'root',
              'group'  => group,
              'mode'   => '0755'
            )

            is_expected.to contain_file('/etc/auto.master.d/home.autofs').with(
              'ensure' => 'present',
              'owner'  => 'root',
              'group'  => group,
              'mode'   => '0644'
            )

            is_expected.to contain_concat('/etc/auto.home').with(
              'ensure' => 'present',
              'owner'  => 'root',
              'group'  => group,
              'mode'   => execute ? '0755' : '0644'
            )
          end
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
          is_expected.to compile.and_raise_error(%r{parameter 'mount' expects a Stdlib::Absolutepath|parameter 'mount' expects a match for})
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
          is_expected.to contain_concat(master_map_file)
          is_expected.to contain_concat__fragment('autofs::fragment preamble /data /etc/auto.data').with_target(master_map_file)
          is_expected.to contain_concat('/etc/auto.data')
          is_expected.to contain_concat__fragment('/etc/auto.data_/data_entries').with_target('/etc/auto.data')
          is_expected.not_to contain_file('/data').with('ensure' => 'directory')
        end
      end

      context 'with special -hosts map' do
        let(:title) { 'auto.NET' }
        let(:params) do
          {
            mount: '/net',
            mapfile_manage: false,
            mapfile: '-hosts'
          }
        end

        it do
          is_expected.to contain_concat(master_map_file)
          is_expected.to contain_concat__fragment('autofs::fragment preamble /net -hosts').with_target(master_map_file)
        end
      end

      context 'with map format option' do
        let(:title) { '/data' }
        let(:params) do
          {
            mapfile: 'file,sun:/etc/auto.data',
            mapfile_manage: false
          }
        end

        it do
          is_expected.to compile
          is_expected.to contain_concat(master_map_file)
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
            mapfile: 'yp:mnt.map',
            mapfile_manage: false
          }
        end

        it do
          is_expected.to compile
          is_expected.to contain_concat(master_map_file)
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
          is_expected.to contain_file_line('remove_contents_/data_/etc/auto.data').with(
            ensure: 'absent',
            path: master_map_file,
            match: "^/data /etc/auto.data \n"
          )
          is_expected.not_to contain_concat__fragment('autofs::fragment preamble /data /etc/auto.data')
          is_expected.to contain_concat('/etc/auto.data').with_ensure('absent')
          is_expected.not_to contain_concat__fragment('/etc/auto.data_/data_entries')
        end
      end
    end
  end
end
