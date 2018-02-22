require 'spec_helper'
require 'hiera'

describe 'autofs', type: :class do
  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }

  hiera = Hiera.new(config: 'spec/fixtures/hiera/hiera.yaml')

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
  end

  context 'it should create auto.home' do
    mounts = hiera.lookup('homedir', nil, nil)
    maps = hiera.lookup('homedir_maps', nil, nil)
    let(:params) { { mounts: mounts } }

    it 'is expected to have auto.home hiera values' do
      expect(mounts).to include(
        'mount'       => '/home',
        'mapfile'     => '/etc/auto.home',
        'mapcontents' => %w[test foo bar],
        'options'     => '--timeout=120',
        'order'       => 1
      )
    end
    it 'is expected to have auto.home hiera values' do
      expect(maps).to include(
        'mapfile'     => '/etc/auto.home',
        'mapcontents' => '/home /another'
      )
    end
  end

  context 'it should create home direct mount' do
    mounts = hiera.lookup('direct', nil, nil)
    let(:params) { { mounts: mounts } }

    it 'is expected to have direct mount hiera values' do
      expect(mounts).to include(
        'mount'       => '/-',
        'mapfile'     => '/etc/auto.home',
        'mapcontents' => %w[/home\ /test /home\ /foo /home\ /bar],
        'options'     => '--timeout=120',
        'order'       => 1
      )
    end
  end

  context 'hiera_confdir_test' do
    mounts = hiera.lookup('confdir', nil, nil)
    let(:params) { { mounts: mounts } }

    it 'is expected to have auto.master.d hiera values' do
      expect(mounts).to include(
        'mount'       => '/home',
        'mapfile'     => '/etc/auto.home',
        'mapcontents' => %w[*\ -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl\ server.example.com:/path/to/home/shares],
        'options'     => '--timeout=120',
        'order'       => 1,
        'use_dir'     => true
      )
    end
  end

  context 'should remove the mount' do
    mounts = hiera.lookup('rmdir', nil, nil)
    let(:params) { { mounts: mounts } }

    it 'is expected to remove the mount' do
      expect(mounts).to include(
        'ensure'  => 'absent',
        'mapfile' => '/etc/auto.home'
      )
    end
  end

  context 'Parameter is not a hash' do
    mounts = 'string'
    let(:params) { { mounts: mounts } }

    it 'is expected to fail' do
      is_expected.to compile.and_raise_error(%r{parameter 'mounts' expects a Hash value})
    end
  end
end
