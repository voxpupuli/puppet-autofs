require 'spec_helper'
describe 'autofs::mounts', :type => :class do
  context 'hiera_test' do
    hiera = Hiera.new(:config => 'spec/fixtures/hiera/hiera.yaml')
    mounts = hiera.lookup('', nil, nil)
    let(:params) {{ :mount => mounts}}
  end
end
