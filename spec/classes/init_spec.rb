require 'spec_helper'
describe 'autofs', :type => :class do

  it { should contain_class('autofs::package') }
#  it { should contain_class('autofs::config') }
#  it { should contain_class('autofs::service') }

end
