require 'spec_helper'
describe 'autofs::mount', :type => :define do
  let(:title) { 'auto.home' }
  let(:params) { {
      :mount => '/home',
      :mapfile => '/etc/auto.home',
      :mapcontents => 'test',
      :options => '--timeout=120',
      :order => '01'
  }}

  it { should contain_file('/etc/auto.home') }

end