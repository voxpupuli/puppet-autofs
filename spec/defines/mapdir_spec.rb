# frozen_string_literal: true

require 'spec_helper'
describe 'autofs::mapdir', type: :define do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include autofs' }
      let(:title) { '/etc/auto.master.d' }

      # Plain helpers derived from facts; kept out of `let` to avoid
      # bloating the memoized helper count per example group.
      def group
        case facts['os']['family']
        when 'AIX' then 'system'
        when 'FreeBSD' then 'wheel'
        else 'root'
        end
      end

      context 'with default parameters' do
        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_file(title)
            .with(ensure: 'directory', owner: 'root', group: group, mode: '0755')
        end
      end

      context 'with autofs::map_dir_mode overridden' do
        let(:pre_condition) { 'class { "autofs": map_dir_mode => "0700" }' }

        it { is_expected.to contain_file(title).with_mode('0700') }
      end

      context 'with an explicit path' do
        let(:title) { 'mydir' }
        let(:params) { { path: '/etc/auto.master.d/mydir' } }

        it { is_expected.to contain_file('/etc/auto.master.d/mydir').with_ensure('directory') }
      end

      context 'with two instances naming the same directory' do
        let(:pre_condition) do
          <<-PUPPET
            include autofs
            autofs::mapdir { 'second': path => '#{title}' }
          PUPPET
        end

        # Proves ensure_resource collapses the shared File resource instead of
        # raising a duplicate resource declaration.
        it { is_expected.to compile.with_all_deps }
      end

      # purge_map_dir is the default value of purge and recurse.
      context 'with purge_map_dir true at the class level' do
        let(:pre_condition) { 'class { "autofs": purge_map_dir => true }' }

        it { is_expected.to contain_file(title).with(purge: true, recurse: true) }
      end

      context 'with an explicit purge override' do
        let(:pre_condition) { 'class { "autofs": purge_map_dir => true }' }
        let(:params) { { purge: false } }

        it { is_expected.to contain_file(title).with(purge: false, recurse: true) }
      end

      context 'with an explicit recurse override' do
        let(:pre_condition) { 'class { "autofs": purge_map_dir => true }' }
        let(:params) { { recurse: false } }

        it { is_expected.to contain_file(title).with(purge: true, recurse: false) }
      end
    end
  end
end
