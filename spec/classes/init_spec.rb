require 'spec_helper'
describe 'autofs' do

  context 'with defaults for all parameters' do
    it { should contain_class('autofs') }
    it { should contain_class('autofs::install'.that_comes_before('Class[autofs::config]'))}
    it { should contain_class('autofs::config'.that_comes_before('Class[autofs::sevice]'))}
    it { should compile.with_all_deps }
  end

end
