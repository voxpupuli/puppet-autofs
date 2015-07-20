require 'spec_helper'
describe 'autofs::config', :type => :class do
  it do
    should contain_file('master_file').with_ensure('file').with_path('/etc/auto.master')
  end
end
