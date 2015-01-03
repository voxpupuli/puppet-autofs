require 'spec_helper'
describe 'autofs' do

  context 'with defaults for all parameters' do
    it { should contain_class('autofs') }
    it { should compile.with_all_deps }
  end

end
