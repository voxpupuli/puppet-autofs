require 'spec_helper'

describe 'autofs::map', type: :define do
  on_supported_os.each do |os, facts|
    let(:pre_condition) { 'include autofs' }

    context "on #{os}" do
      let(:title) { 'data' }
      let(:facts) do
        facts.merge(concat_basedir: '/etc')
      end
      let(:params) do
        {
          mapfile: '/etc/auto.data',
          mapcontents: ['test foo bar']
        }
      end

      context 'with default parameters' do
        it do
          is_expected.not_to contain_concat('/etc/auto.data')
          is_expected.to contain_concat__fragment('/etc/auto.data_data_entries').with(
            'target' => '/etc/auto.data'
          )
        end
      end

      context 'with bare string mapcontents' do
        let(:params) do
          {
            mapfile: '/etc/auto.data',
            mapcontents: 'test foo bar'
          }
        end

        it { is_expected.to compile }
      end
    end
  end
end
