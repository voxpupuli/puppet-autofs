require 'spec_helper'
describe 'autofs::map', type: :define do
  let(:title) { 'data' }

  let(:facts) do
    {
      concat_basedir: '/etc'
    }
  end

  let(:params) do
    {
      mapfile: '/etc/auto.data',
      mapcontent: 'test foo bar',
      order: 0o1
    }
  end

  context 'with default parameters' do
    it do
      is_expected.to contain_concat__fragment('/etc/auto.data_test foo bar').with(
        'target' => '/etc/auto.data',
        'content' => "test foo bar\n"
      )
    end
  end
end
