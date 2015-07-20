require 'spec_helper'
describe 'autofs::config', :type => :class do
  it do
    should contain_concat('/etc/auto.master')
  end
end
