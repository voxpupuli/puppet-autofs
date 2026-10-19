# frozen_string_literal: true

require 'spec_helper'
require 'hiera'

describe 'autofs', type: :class do
  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      def group_value
        case facts['os']['family']
        when 'AIX' then 'system'
        when 'FreeBSD' then 'wheel'
        else 'root'
        end
      end

      def master_map_file_value
        %w[AIX FreeBSD Solaris].include?(facts['os']['family']) ? '/etc/auto_master' : '/etc/auto.master'
      end

      def service_value
        case facts['os']['family']
        when 'AIX' then 'automountd'
        when 'FreeBSD' then 'automount'
        else 'autofs'
        end
      end

      def package_value
        case facts['os']['family']
        when 'AIX'
          'bos.net.nfs.client'
        when 'Solaris'
          if facts['os']['release']['major'].to_s == '11'
            'system/file-system/autofs'
          else
            'SUNWatfsu' # and SUNWatfsr, but close enough
          end
        else
          'autofs'
        end
      end

      context 'main init tests' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('autofs') }
        it { is_expected.to contain_class('autofs::package') }
        it { is_expected.to contain_class('autofs::service') }

        # Check Package and service
        if os_facts['os']['family'] == 'FreeBSD'
          it { is_expected.to contain_service('automountd').with_ensure('running') }
          it { is_expected.to contain_service('autounmountd').with_ensure('running') }
        else
          it { is_expected.to contain_package(package_value).with_ensure('installed') }
          it { is_expected.to contain_service(service_value).that_requires("Package[#{package_value}]") }
          it { is_expected.to contain_service(service_value).with_ensure('running') }
        end
        it { is_expected.to contain_service(service_value).with_enable(true) }
        # The master map is managed by default, so its Concat target exists.
        it { is_expected.to contain_concat(master_map_file_value) }
        # The Hiera fixture declares a confdir mount recorded through the
        # drop-in directory, and the master map class is contained by default.
        it { is_expected.to contain_class('autofs::master') }
        it { is_expected.to contain_autofs__mount('confdir') }
        it { is_expected.to contain_autofs__add_master_entry('/etc/auto.master.d') }
        it { is_expected.to contain_file('/etc/auto.master.d/confdir.autofs') }
        it { is_expected.not_to contain_file('autofs_service_config') }
        it { is_expected.not_to contain_file('autofs_ldap_auth_config') }
      end

      context 'disable package' do
        let(:params) do
          {
            package_ensure: 'absent',
          }
        end

        it { is_expected.to contain_package(package_value).with_ensure('absent') } if os_facts['os']['family'] != 'FreeBSD'
      end

      context 'should declare mount points' do
        let(:params) do
          {
            mounts: {
              'home' => { mount: '/home', mapfile: '/etc/auto.home', options: '--timeout=120', order: 1 },
              '/mnt/other' => { mapfile: '/etc/auto.other' },
              'direct' => { mount: '/-', mapfile: '/etc/auto.direct' },
              'remove this' => { mount: '/unwanted', mapfile: '/etc/auto.unwanted', ensure: 'absent' },
            },
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to have_autofs__mount_resource_count(4)
          expect(subject).to contain_autofs__mount('home')
            .with(mount: '/home', mapfile: '/etc/auto.home', options: '--timeout=120', order: 1)
          expect(subject).to contain_autofs__mount('/mnt/other')
            .with(mapfile: '/etc/auto.other')
          expect(subject).to contain_autofs__mount('direct')
            .with(mount: '/-', mapfile: '/etc/auto.direct')
          expect(subject).to contain_autofs__mount('remove this')
            .with(mount: '/unwanted', ensure: 'absent')
          expect(subject).to have_autofs__mapfile_resource_count(0)
          expect(subject).to have_autofs__mapping_resource_count(0)
          # Each mount contributes exactly one master map entry resource, which
          # autofs::mount delegates to autofs::add_master_entry.
          expect(subject).to have_autofs__add_master_entry_resource_count(4)
          expect(subject).to contain_autofs__add_master_entry('autofs::mount home')
            .with(ensure: 'present', order: 1)
            .with_entry('/home /etc/auto.home --timeout=120')
          expect(subject).to contain_autofs__add_master_entry('autofs::mount /mnt/other')
            .with_entry(%r{\A/mnt/other /etc/auto\.other\s*\z})
          expect(subject).to contain_autofs__add_master_entry('autofs::mount direct')
            .with_entry(%r{\A/- /etc/auto\.direct\s*\z})
          expect(subject).to contain_autofs__add_master_entry('autofs::mount remove this')
            .with_ensure('absent')
          expect(subject).to contain_concat(master_map_file_value)
          expect(subject).to contain_concat__fragment('autofs::add_master_entry autofs::mount home')
            .with_target(master_map_file_value)
            .with_content(%r{\A\s*/home /etc/auto.home --timeout=120\s*\z})
          expect(subject).to contain_concat__fragment('autofs::add_master_entry autofs::mount /mnt/other')
            .with_target(master_map_file_value)
            .with_content(%r{\A\s*/mnt/other /etc/auto.other\s*\z})
          expect(subject).to contain_concat__fragment('autofs::add_master_entry autofs::mount direct')
            .with_target(master_map_file_value)
            .with_content(%r{\A\s*/- /etc/auto.direct\s*\z})
        end
      end

      context 'with manage_auto_master disabled' do
        let(:params) do
          {
            manage_auto_master: false,
            mounts: {
              'home' => { mount: '/home', mapfile: '/etc/auto.home', use_dir: true },
            },
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).not_to contain_concat('/etc/auto.master')
          expect(subject).not_to contain_concat__fragment('autofs::add_master_entry /etc/auto.master.d')
          # The module no longer ensures the drop-in directory itself; it is
          # shipped by the autofs package (or created via add_master_entry's
          # ensure_dir), and only the drop-in files are managed here.
          expect(subject).not_to contain_file('/etc/auto.master.d')
          expect(subject).to contain_file('/etc/auto.master.d/home.autofs')
        end
      end

      context 'should declare mappings directly' do
        let(:params) do
          {
            mounts: {},
            mapfiles: {
              '/etc/auto.data' => {
                mappings: [
                  { 'key' => 'example1', 'options' => 'ro', 'fs' => 'fs.net:/export/example1' },
                  { 'key' => 'example2', 'options' => %w[rw noexec], 'fs' => 'fs.net:/export/example2' },
                  { 'key' => 'example3', 'options' => 'exec', 'fs' => 'fs.net:/export/example3' },
                ],
              },
            },
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_autofs__mapfile('/etc/auto.data')
          expect(subject).to have_autofs__mapping_resource_count(3)
          expect(subject).to contain_autofs__mapping('/etc/auto.data:example1')
          expect(subject).to contain_autofs__mapping('/etc/auto.data:example2')
          expect(subject).to contain_autofs__mapping('/etc/auto.data:example3')
          expect(subject).to contain_concat__fragment('autofs::mapping//etc/auto.data:example1')
            .with(target: '/etc/auto.data')
          expect(subject).to contain_concat__fragment('autofs::mapping//etc/auto.data:example2')
            .with(target: '/etc/auto.data')
          expect(subject).to contain_concat__fragment('autofs::mapping//etc/auto.data:example3')
            .with(target: '/etc/auto.data')
          expect(subject).to contain_concat('/etc/auto.data')
        end
      end

      context 'should declare mappings via the mappings parameter' do
        # The referenced mapfile is declared too, so the fragment has a valid
        # Concat target -- as the README requires.
        let(:params) do
          {
            mounts: {},
            mapfiles: {
              '/mnt/data' => {
                mappings: [
                  { 'key' => 'viaMapfile', 'options' => 'ro', 'fs' => 'fs.net:/export/viaMapfile' },
                ],
              },
            },
            mappings: {
              'dataA' => { mapfile: '/mnt/data', key: 'dataA', options: 'ro', fs: 'remote.com:/exports/dataA' },
              'dataB' => { mapfile: '/mnt/data', key: 'dataB', options: 'rw', fs: 'remote.com:/exports/dataB' },
            },
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          # one mapping from the mapfile plus two from the mappings parameter
          expect(subject).to have_autofs__mapping_resource_count(3)
          expect(subject).to contain_autofs__mapping('dataA')
            .with(mapfile: '/mnt/data', key: 'dataA', options: 'ro', fs: 'remote.com:/exports/dataA')
          expect(subject).to contain_autofs__mapping('dataB')
            .with(mapfile: '/mnt/data', key: 'dataB', options: 'rw', fs: 'remote.com:/exports/dataB')
          expect(subject).to contain_concat__fragment('autofs::mapping/dataA')
            .with_target('/mnt/data')
            .with_content(%r{\A\s*dataA\s+-ro\s+remote\.com:/exports/dataA\s*\z})
          expect(subject).to contain_concat__fragment('autofs::mapping/dataB')
            .with_target('/mnt/data')
            .with_content(%r{\A\s*dataB\s+-rw\s+remote\.com:/exports/dataB\s*\z})
          # The mapfile-provided mapping is declared end to end too.
          expect(subject).to contain_autofs__mapping('/mnt/data:viaMapfile')
            .with(mapfile: '/mnt/data', key: 'viaMapfile', options: 'ro', fs: 'fs.net:/export/viaMapfile')
          expect(subject).to contain_concat__fragment('autofs::mapping//mnt/data:viaMapfile')
            .with_target('/mnt/data')
            .with_content(%r{\A\s*viaMapfile\s+-ro\s+fs\.net:/export/viaMapfile\s*\z})
          expect(subject).to contain_autofs__mapfile('/mnt/data')
            .with(path: '/mnt/data')
          # The shared mapfile's Concat is created by its mapfile resource.
          expect(subject).to contain_concat('/mnt/data')
            .with(owner: 'root', group: group_value, mode: '0644')
        end
      end

      context 'should declare master-map entries via the add_master_entries parameter' do
        let(:params) do
          {
            mounts: {},
            add_master_entries: {
              'myapp' => { entry: '+dir:/etc/auto.master.d/myapp', ensure_dir: true },
              'nis_maps' => { entry: '+auto.master' },
            },
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to have_autofs__add_master_entry_resource_count(2)
          expect(subject).to contain_autofs__add_master_entry('myapp')
            .with(ensure: 'present', order: 50, ensure_dir: true)
            .with_entry('+dir:/etc/auto.master.d/myapp')
          expect(subject).to contain_autofs__add_master_entry('nis_maps')
            .with_entry('+auto.master')
          # A present +dir: entry with ensure_dir also creates the directory.
          expect(subject).to contain_autofs__mapdir('myapp')
            .with_path('/etc/auto.master.d/myapp')
          expect(subject).to contain_file('/etc/auto.master.d/myapp')
            .with(ensure: 'directory', owner: 'root', group: group_value, mode: '0755')
          expect(subject).to contain_concat__fragment('autofs::add_master_entry myapp')
            .with_target(master_map_file_value)
            .with_content(%r{\A\+dir:/etc/auto\.master\.d/myapp\s*\z})
            .that_requires('Autofs::Mapdir[myapp]')
          expect(subject).to contain_concat__fragment('autofs::add_master_entry nis_maps')
            .with_target(master_map_file_value)
            .with_content(%r{\A\+auto\.master\s*\z})
          expect(subject).to contain_concat(master_map_file_value)
            .with(group: group_value)
        end
      end

      context 'should declare map files' do
        let(:params) do
          {
            mounts: {},
            mapfiles: {
              'home' => { path: '/etc/auto.home', mappings: [{ 'key' => 'user1', 'options' => 'rw,exec', 'fs' => 'users.com:/x/user1' }] },
              '/mnt/defaults' => {},
              'unwanted' => { path: '/etc/auto.evil', ensure: 'absent' },
            },
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_autofs__mapfile('home')
            .with(path: '/etc/auto.home', mappings: [{ 'key' => 'user1', 'options' => 'rw,exec', 'fs' => 'users.com:/x/user1' }])
          expect(subject).to contain_autofs__mapfile('/mnt/defaults')
          expect(subject).to contain_autofs__mapfile('unwanted')
            .with(path: '/etc/auto.evil', ensure: 'absent')
          expect(subject).to have_autofs__mapfile_resource_count(3)
          expect(subject).to have_autofs__mount_resource_count(0)
          expect(subject).to have_autofs__mapping_resource_count(1)
          expect(subject).to contain_autofs__mapping('/etc/auto.home:user1')
            .with(mapfile: '/etc/auto.home', key: 'user1', options: 'rw,exec', fs: 'users.com:/x/user1')
          expect(subject).to contain_concat__fragment('autofs::mapping//etc/auto.home:user1')
            .with(target: '/etc/auto.home')
          expect(subject).to contain_concat('/etc/auto.home')
            .with(owner: 'root', group: group_value, mode: '0644')
          expect(subject).to contain_concat('/etc/auto.evil')
            .with(ensure: 'absent')
          expect(subject).to contain_concat('/mnt/defaults')
        end
      end

      context 'should declare automaster mapfile with nismap' do
        let(:params) do
          {
            manage_auto_master: false,
            mounts: {},
            mapfiles: {
              'master' => { path: '/etc/auto.master', mappings: [{ 'key' => '+', 'fs' => 'auto.master' }] },
            },
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_autofs__mapfile('master')
            .with(path: '/etc/auto.master', mappings: [{ 'key' => '+', 'fs' => 'auto.master' }])
          expect(subject).to have_autofs__mapfile_resource_count(1)
          expect(subject).to have_autofs__mount_resource_count(0)
          expect(subject).to have_autofs__mapping_resource_count(1)
          expect(subject).to contain_autofs__mapping('/etc/auto.master:+')
            .with(mapfile: '/etc/auto.master', key: '+', fs: 'auto.master')
          expect(subject).to contain_concat__fragment('autofs::mapping//etc/auto.master:+')
            .with(target: '/etc/auto.master')
          expect(subject).to contain_concat('/etc/auto.master')
        end
      end

      # Regression: acceptance 'master nismap inclusion test' uses the default
      # manage_auto_master (true), so autofs::master owns the Concat for the
      # master map.  A mapfile targeting that same path must defer to it rather
      # than declaring a second Concat, which is what broke the GitHub builds.
      context 'with mapfile on the managed master map (nismap)' do
        let(:params) do
          {
            mapfiles: {
              'master' => { path: '/etc/auto.master', mappings: [{ 'key' => '+', 'fs' => 'auto.master' }] },
            },
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_autofs__mapping('/etc/auto.master:+')
            .with(mapfile: '/etc/auto.master', key: '+', fs: 'auto.master')
          expect(subject).to contain_concat('/etc/auto.master')
        end
      end

      context 'with $mounts not a hash' do
        let(:params) { { mounts: 'string' } }

        it 'is expected to fail' do
          expect(subject).to compile.and_raise_error(%r{parameter 'mounts' expects a Hash value})
        end
      end

      context 'with $manage_service_config enabled' do
        let(:params) { { manage_service_config: true } }

        it { is_expected.to compile.with_all_deps }

        it {
          expect(subject).to contain_file('autofs_service_config').with_content(%r{USE_MISC_DEVICE="yes"})
        }
      end

      context 'with $manage_service_config enabled with options' do
        let(:params) do
          {
            manage_service_config: true,
            service_conf_options: {
              LDAP_URI: 'ldap://ldap.example.org',
              SEARCH_BASE: 'dc=example,dc=org',
              MAP_OBJECT_CLASS: 'automountMap',
              ENTRY_OBJECT_CLASS: 'automount',
              MAP_ATTRIBUTE: 'ou',
              ENTRY_ATTRIBUTE: 'cn',
              VALUE_ATTRIBUTE: 'automountInformation',
            },
          }
        end

        it { is_expected.to compile.with_all_deps }

        it {
          expect(subject).to contain_file('autofs_service_config')
            .with_content(%r{LDAP_URI=ldap://ldap\.example\.org})
            .with_content(%r{SEARCH_BASE=dc=example,dc=org})
            .with_content(%r{MAP_OBJECT_CLASS=automountMap})
            .with_content(%r{ENTRY_OBJECT_CLASS=automount})
            .with_content(%r{MAP_ATTRIBUTE=ou})
            .with_content(%r{ENTRY_ATTRIBUTE=cn})
            .with_content(%r{VALUE_ATTRIBUTE=automountInformation})
        }
      end

      context 'with $manage_ldap_auth_conf enabled' do
        let(:params) { { manage_ldap_auth_conf: true } }

        it { is_expected.to compile.with_all_deps }

        it {
          expect(subject).to contain_file('autofs_ldap_auth_config')
            .with_content(%r{authrequired="no"})
            .with_content(%r{tlsrequired="no"})
            .with_content(%r{usetls="no"})
        }
      end

      context 'with $manage_ldap_auth_conf enabled with options' do
        let(:params) do
          {
            manage_ldap_auth_conf: true,
            ldap_auth_config: {
              usetls: 'yes',
              tlsrequired: 'yes',
              authrequired: 'yes',
            },
          }
        end

        it { is_expected.to compile.with_all_deps }

        it {
          expect(subject).to contain_file('autofs_ldap_auth_config')
            .with_content(%r{authrequired="yes"})
            .with_content(%r{tlsrequired="yes"})
            .with_content(%r{usetls="yes"})
        }
      end

      context 'with reload_command set' do
        let(:params) { { reload_command: '/usr/sbin/automount --remount-all' } }

        it do
          # reload_command is the documented alternative to a full service
          # restart: the exec runs refreshonly and only after the service.
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_exec('automount-reload')
            .with_command('/usr/sbin/automount --remount-all')
            .with_path('/sbin:/usr/sbin')
            .with_refreshonly(true)
            .that_requires("Service[#{service_value}]")
        end
      end

      context 'with the service stopped and disabled on boot' do
        # Documented "disable the service" example (README).
        let(:params) { { service_ensure: 'stopped', service_enable: false } }

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_service(service_value)
            .with_ensure('stopped')
            .with_enable(false)
        end
      end

      context 'with service_use_misc_device set to no' do
        let(:params) { { manage_service_config: true, service_use_misc_device: 'no' } }

        it {
          # README: service_use_misc_device sets USE_MISC_DEVICE in the
          # service config file.
          expect(subject).to contain_file('autofs_service_config')
            .with_content(%r{USE_MISC_DEVICE="no})
        }
      end

      context 'with service_options set' do
        let(:params) { { manage_service_config: true, service_options: %w[--ghost --ghost-permission 0755] } }

        it {
          # README: service_options is appended to the OPTIONS= line.
          expect(subject).to contain_file('autofs_service_config')
            .with_content(%r{OPTIONS="--ghost --ghost-permission 0755})
        }
      end

      context 'with purge_map_dir enabled and a use_dir mount' do
        let(:params) do
          {
            purge_map_dir: true,
            mounts: {
              'home' => { mount: '/home', mapfile: '/etc/auto.home', use_dir: true, ensure_dir: true },
            },
          }
        end

        it do
          # The primary documented scenario: autofs::mapdir mirrors (purges)
          # the drop-in directory from the purge_map_dir default while the
          # mount's own drop-in file is still declared and so is not purged.
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_file('/etc/auto.master.d')
            .with('purge' => true, 'recurse' => true)
          expect(subject).to contain_file('/etc/auto.master.d/home.autofs')
          # The +dir: drop-in directory entry is recorded in the master map,
          # and only after the directory itself has been ensured.
          expect(subject).to contain_autofs__mapdir('/etc/auto.master.d')
            .with_path('/etc/auto.master.d')
          expect(subject).to contain_concat__fragment('autofs::add_master_entry /etc/auto.master.d')
            .with_target(master_map_file_value)
            .with_content(%r{\A\+dir:/etc/auto\.master\.d\s*\z})
            .that_requires('Autofs::Mapdir[/etc/auto.master.d]')
        end
      end
    end
  end
end
