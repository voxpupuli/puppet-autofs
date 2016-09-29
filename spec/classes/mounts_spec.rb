require 'spec_helper'
describe 'autofs::mounts', :type => :class do
  hiera = Hiera.new(:config => 'spec/fixtures/hiera/hiera.yaml')

  context 'it should create auto.home' do
    mounts = hiera.lookup('homedir', nil, nil)
    let(:params) {{ :mount => mounts}}
  end

  context '' do
    mounts = hiera.lookup('direct', nil, nil)
    let(:params) {{ :mount => mounts }}
  end

  context 'hiera_confdir_test' do
    mounts = hiera.lookup('confdir', nil, nil)
    let(:params) {{ :mount => mounts }}
  end
end
