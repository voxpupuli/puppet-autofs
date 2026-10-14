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
          expect(subject).to contain_concat(master_map_file_value)
          expect(subject).to contain_concat__fragment('autofs::fragment preamble /home /etc/auto.home')
            .with_target(master_map_file_value)
          expect(subject).to contain_concat__fragment('autofs::fragment preamble /mnt/other /etc/auto.other')
            .with_target(master_map_file_value)
          expect(subject).to contain_concat__fragment('autofs::fragment preamble /- /etc/auto.direct')
            .with_target(master_map_file_value)
          expect(subject).to contain_file_line("#{master_map_file_value}::/unwanted_/etc/auto.unwanted")
            .with(ensure: 'absent', path: master_map_file_value)
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
          expect(subject).not_to contain_concat__fragment('autofs::fragment preamble map directory')
          expect(subject).to contain_file('/etc/auto.master.d/home.autofs')
          expect(subject).to contain_file('/etc/auto.master.d')
            .with(ensure: 'directory', owner: 'root', group: group_value)
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
    end
  end
end
