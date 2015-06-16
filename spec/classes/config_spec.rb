require 'spec_helper'
describe 'autofs::config', :type => :class do
  hiera = Hiera.new(:config => 'spec/fixtures/hiera/hiera.yaml')
  mapoptions = hiera.lookup('mapOptions', nil, nil)
  let(:params) {{ :map_options => mapoptions}}


end