require 'spec_helper'
require 'hiera'

describe 'autofs', type: :class do
  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }

  # hiera = Hiera.new(config: 'spec/fixtures/hiera/hiera.yaml')

  on_supported_os.each do |os, facts|
    case facts[:os]['family']
    when 'AIX'
      package = 'bos.net.nfs.client'
      service = 'automountd'
    when 'Solaris'
      package = if facts[:os]['release']['major'].to_s == '11'
                  'system/file-system/autofs'
                else
                  'SUNWatfsu' # and SUNWatfsr, but close enough
                end
      service = 'autofs'
    else
      package = 'autofs'
      service = 'autofs'
    end

    context "on #{os}" do
      let :facts do
        facts
      end

      context 'main init tests' do
        let(:facts) do
          facts.merge(concat_basedir: '/etc')
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('autofs') }
        it { is_expected.to contain_class('autofs::package') }
        it { is_expected.to contain_class('autofs::service') }

        # Check Package and service
        it { is_expected.to contain_package(package).with_ensure('installed') }
        it { is_expected.to contain_service(service).that_requires("Package[#{package}]") }
        it { is_expected.to contain_service(service).with_ensure('running') }
        it { is_expected.to contain_service(service).with_enable(true) }
      end
    end

    context 'disable package' do
      let(:facts) do
        facts.merge(concat_basedir: '/etc')
      end
      let(:params) do
        {
          package_ensure: 'absent'
        }
      end

      it { is_expected.to contain_package(package).with_ensure('absent') }
    end

    context 'should declare mount points' do
      let(:params) do
        {
          mounts: {
            'home'        => { mount: '/home', mapfile: '/etc/auto.home', options: '--timeout=120', order: 1 },
            '/mnt/other'  => { mapfile: '/etc/auto.other' },
            'direct'      => { mount: '/-', mapfile: '/etc/auto.direct' },
            'remove this' => { mount: '/unwanted', mapfile: '/etc/auto.unwanted', ensure: 'absent' }
          }
        }
      end

      it do
        is_expected.to compile.with_all_deps
        is_expected.to have_autofs__mount_resource_count(4)
        is_expected.to contain_autofs__mount('home').
          with(mount: '/home', mapfile: '/etc/auto.home', options: '--timeout=120', order: 1)
        is_expected.to contain_autofs__mount('/mnt/other').
          with(mapfile: '/etc/auto.other')
        is_expected.to contain_autofs__mount('direct').
          with(mount: '/-', mapfile: '/etc/auto.direct')
        is_expected.to contain_autofs__mount('remove this').
          with(mount: '/unwanted', ensure: 'absent')
        is_expected.to have_autofs__map_resource_count(0)
        is_expected.to have_autofs__mapfile_resource_count(0)
        is_expected.to have_autofs__mapping_resource_count(0)
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
        is_expected.to compile.with_all_deps
        is_expected.to contain_autofs__mapfile('home').
          with(path: '/etc/auto.home', mappings: home_mappings)
        is_expected.to contain_autofs__mapfile('/mnt/defaults')
        is_expected.to contain_autofs__mapfile('unwanted').
          with(path: '/etc/auto.evil', ensure: 'absent')
        is_expected.to have_autofs__mapfile_resource_count(3)
        is_expected.to have_autofs__mount_resource_count(0)
        is_expected.to have_autofs__map_resource_count(0)
      end
    end

    context 'with $mounts not a hash' do
      let(:params) { { mounts: 'string' } }

      it 'is expected to fail' do
        is_expected.to compile.and_raise_error(%r{parameter 'mounts' expects a Hash value})
      end
    end
  end
end
