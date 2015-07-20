require 'spec_helper'
describe 'autofs::config', :type => :class do
  let(:facts) do
    {
      :concat_basedir => '/etc'
    }
  end
  it do
    should contain_concat('/etc/auto.master')
  end
end
