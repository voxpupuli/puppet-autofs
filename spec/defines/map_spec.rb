require 'spec_helper'

describe 'autofs::map', type: :define do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:title) { 'data' }
      let(:pre_condition) { 'include autofs' }
      let(:group) do
        case facts[:os]['family']
        when 'AIX' then 'system'
        when 'FreeBSD' then 'wheel'
        else 'root'
        end
      end
      let(:facts) { os_facts }
      let(:params) do
        {
          mapfile: '/etc/auto.data',
          mapcontents: ['test foo bar']
        }
      end

      context 'with default parameters' do
        it do
          is_expected.to contain_concat('/etc/auto.data').with(
            'ensure' => 'present',
            'owner'  => 'root',
            'group'  => group,
            'mode'   => '0644'
          )
          is_expected.to contain_concat__fragment('/etc/auto.data_data_entries').with(
            'target' => '/etc/auto.data'
          )
        end
      end

      context 'with bare string mapcontents' do
        let(:params) { super().merge(mapcontents: 'test foo bar') }

        it { is_expected.to compile }
      end
    end
  end
end
