# frozen_string_literal: true

require 'spec_helper'

describe 'autofs::master', type: :class do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include autofs' }
      let(:master_map_file) { %w[AIX FreeBSD Solaris].include?(facts['os']['family']) ? '/etc/auto_master' : '/etc/auto.master' }
      let(:group) do
        case facts['os']['family']
        when 'AIX' then 'system'
        when 'FreeBSD' then 'wheel'
        else 'root'
        end
      end

      context 'with manage_auto_master enabled (default)' do
        it { is_expected.to compile.with_all_deps }

        it do
          expect(subject).to contain_concat(master_map_file)
            .with(owner: 'root', group: group, mode: '0644', ensure_newline: true)
        end
      end

      context 'with custom map file permissions' do
        let(:pre_condition) do
          'class { "autofs": map_file_owner => "autofs", map_file_group => "autofs", map_file_mode => "0640" }'
        end

        it { is_expected.to compile.with_all_deps }

        it do
          expect(subject).to contain_concat(master_map_file)
            .with(owner: 'autofs', group: 'autofs', mode: '0640')
        end
      end

      context 'with manage_auto_master disabled' do
        let(:pre_condition) { 'class { "autofs": manage_auto_master => false }' }

        it { is_expected.not_to compile.with_all_deps }
      end
    end
  end
end
