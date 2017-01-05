require 'spec_helper'
require 'hiera'

describe 'autofs::mounts', :type => :class do
  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
  hiera = Hiera.new(:config => 'spec/fixtures/hiera/hiera.yaml')

  context 'it should create auto.home' do
    mounts = hiera.lookup('homedir', nil, nil)
    let(:params) {{ :mount => mounts }}
  end

  context 'it should create home direct mount' do
    mounts = hiera.lookup('direct', nil, nil)
    let(:params) {{ :mount => mounts }}
  end

  context 'hiera_confdir_test' do
    mounts = hiera.lookup('confdir', nil, nil)
    let(:params) {{ :mount => mounts }}
  end
end
