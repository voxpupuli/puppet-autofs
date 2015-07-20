require 'spec_helper'
describe 'autofs::config', :type => :class do
  it do
    let(:facts) do
      {
        :concat_basedir => '/etc'
      }
    end
    should contain_concat('/etc/auto.master')
  end
end
