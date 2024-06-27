# frozen_string_literal: true

require 'spec_helper'
require 'hiera'

describe 'autofs', type: :class do
  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:service) do
        case facts['os']['family']
        when 'AIX' then 'automountd'
        when 'FreeBSD' then 'automount'
        else 'autofs'
        end
      end
      let(:package) do
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
          it { is_expected.to contain_package(package).with_ensure('installed') }
          it { is_expected.to contain_service(service).that_requires("Package[#{package}]") }
          it { is_expected.to contain_service(service).with_ensure('running') }
        end
        it { is_expected.to contain_service(service).with_enable(true) }
        it { is_expected.not_to contain_file('autofs_service_config') }
        it { is_expected.not_to contain_file('autofs_ldap_auth_config') }
      end

      context 'disable package' do
        let(:params) do
          {
            package_ensure: 'absent'
          }
        end

        it { is_expected.to contain_package(package).with_ensure('absent') } if os_facts['os']['family'] != 'FreeBSD'
      end

      context 'should declare mount points' do
        let(:params) do
          {
            mounts: {
              'home' => { mount: '/home', mapfile: '/etc/auto.home', options: '--timeout=120', order: 1 },
              '/mnt/other' => { mapfile: '/etc/auto.other' },
              'direct' => { mount: '/-', mapfile: '/etc/auto.direct' },
              'remove this' => { mount: '/unwanted', mapfile: '/etc/auto.unwanted', ensure: 'absent' }
            }
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to have_autofs__mount_resource_count(4)
          expect(subject).to contain_autofs__mount('home').
            with(mount: '/home', mapfile: '/etc/auto.home', options: '--timeout=120', order: 1)
          expect(subject).to contain_autofs__mount('/mnt/other').
            with(mapfile: '/etc/auto.other')
          expect(subject).to contain_autofs__mount('direct').
            with(mount: '/-', mapfile: '/etc/auto.direct')
          expect(subject).to contain_autofs__mount('remove this').
            with(mount: '/unwanted', ensure: 'absent')
          expect(subject).to have_autofs__map_resource_count(0)
          expect(subject).to have_autofs__mapfile_resource_count(0)
          expect(subject).to have_autofs__mapping_resource_count(0)
        end
      end

      context 'should declare map files' do
        home_mappings = [
          { 'key' => 'user1', 'options' => 'rw,exec', 'fs' => 'users.com:/x/user1' }
        ]
        let(:params) do
          {
            mounts: {},
            mapfiles: {
              'home' => { path: '/etc/auto.home', mappings: home_mappings },
              '/mnt/defaults' => {},
              'unwanted' => { path: '/etc/auto.evil', ensure: 'absent' }
            },
            maps: :undef
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_autofs__mapfile('home').
            with(path: '/etc/auto.home', mappings: home_mappings)
          expect(subject).to contain_autofs__mapfile('/mnt/defaults')
          expect(subject).to contain_autofs__mapfile('unwanted').
            with(path: '/etc/auto.evil', ensure: 'absent')
          expect(subject).to have_autofs__mapfile_resource_count(3)
          expect(subject).to have_autofs__mount_resource_count(0)
          expect(subject).to have_autofs__map_resource_count(0)
        end
      end

      context 'should declare automaster mapfile with nismap' do
        master_mappings = [
          { 'key' => '+', 'fs' => 'auto.master' }
        ]
        let(:params) do
          {
            mounts: {},
            mapfiles: {
              'master' => { path: '/etc/auto.master', mappings: master_mappings },
            },
            maps: :undef
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_autofs__mapfile('master').
            with(path: '/etc/auto.master', mappings: master_mappings)
          expect(subject).to have_autofs__mapfile_resource_count(1)
          expect(subject).to have_autofs__mount_resource_count(0)
          expect(subject).to have_autofs__map_resource_count(0)
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
              VALUE_ATTRIBUTE: 'automountInformation'
            }
          }
        end

        it { is_expected.to compile.with_all_deps }

        it {
          expect(subject).to contain_file('autofs_service_config').
            with_content(%r{LDAP_URI=ldap://ldap\.example\.org}).
            with_content(%r{SEARCH_BASE=dc=example,dc=org}).
            with_content(%r{MAP_OBJECT_CLASS=automountMap}).
            with_content(%r{ENTRY_OBJECT_CLASS=automount}).
            with_content(%r{MAP_ATTRIBUTE=ou}).
            with_content(%r{ENTRY_ATTRIBUTE=cn}).
            with_content(%r{VALUE_ATTRIBUTE=automountInformation})
        }
      end

      context 'with $manage_ldap_auth_conf enabled' do
        let(:params) { { manage_ldap_auth_conf: true } }

        it { is_expected.to compile.with_all_deps }

        it {
          expect(subject).to contain_file('autofs_ldap_auth_config').
            with_content(%r{authrequired="no"}).
            with_content(%r{tlsrequired="no"}).
            with_content(%r{usetls="no"})
        }
      end

      context 'with $manage_ldap_auth_conf enabled with options' do
        let(:params) do
          {
            manage_ldap_auth_conf: true,
            ldap_auth_config: {
              usetls: 'yes',
              tlsrequired: 'yes',
              authrequired: 'yes'
            }
          }
        end

        it { is_expected.to compile.with_all_deps }

        it {
          expect(subject).to contain_file('autofs_ldap_auth_config').
            with_content(%r{authrequired="yes"}).
            with_content(%r{tlsrequired="yes"}).
            with_content(%r{usetls="yes"})
        }
      end
    end
  end
end
