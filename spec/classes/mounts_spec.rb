require 'spec_helper'
require 'hiera'

describe 'autofs::mounts', type: :class do
  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
  hiera = Hiera.new(config: 'spec/fixtures/hiera/hiera.yaml')

  context 'it should create auto.home' do
    mounts = hiera.lookup('homedir', nil, nil)
    let(:params) { { mount: mounts } }
    it 'is expected to have auto.home hiera values' do
      expect(mounts).to include(
        'mount' => '/home',
        'mapfile' => '/etc/auto.home',
        'mapcontents' => %w(test foo bar),
        'options' => '--timeout=120',
        'order' => 1
      )
    end
  end

  context 'it should create home direct mount' do
    mounts = hiera.lookup('direct', nil, nil)
    let(:params) { { mount: mounts } }
    it 'is expected to have direct mount hiera values' do
      expect(mounts).to include(
        'mount' => '/-',
        'mapfile' => '/etc/auto.home',
        'mapcontents' => %w(/home\ /test /home\ /foo /home\ /bar),
        'options' => '--timeout=120',
        'order' => 1
      )
    end
  end

  context 'hiera_confdir_test' do
    mounts = hiera.lookup('confdir', nil, nil)
    let(:params) { { mount: mounts } }
    it 'is expected to have auto.master.d hiera values' do
      expect(mounts).to include(
        'mount' => '/home',
        'mapfile' => '/etc/auto.home',
        'mapcontents' => %w(*\ -user,rw,soft,intr,rsize=32768,wsize=32768,tcp,nfsvers=3,noacl\ server.example.com:/path/to/home/shares),
        'options' => '--timeout=120',
        'order' => 1,
        'use_dir' => true
      )
    end
  end
end
