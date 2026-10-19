# frozen_string_literal: true

require 'spec_helper'
describe 'autofs::add_master_entry', type: :define do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { 'include autofs' }

      # Plain helpers derived from facts; kept out of `let` to avoid
      # bloating the memoized helper count per example group.
      def group
        case facts['os']['family']
        when 'AIX' then 'system'
        when 'FreeBSD' then 'wheel'
        else 'root'
        end
      end

      def master_map_file
        %w[AIX FreeBSD Solaris].include?(facts['os']['family']) ? '/etc/auto_master' : '/etc/auto.master'
      end

      context 'with default entry (uses title)' do
        let(:title) { '+dir:/etc/auto.master.d/myapp' }

        it do
          expect(subject).to contain_concat(master_map_file)
            .with(group: group)
          expect(subject).to contain_concat__fragment('autofs::add_master_entry +dir:/etc/auto.master.d/myapp')
            .with(
              'target' => master_map_file,
              'content' => "+dir:/etc/auto.master.d/myapp\n",
            )
          expect(subject).to have_concat_resource_count(1)
        end
      end

      context 'with explicit entry parameter' do
        let(:title) { 'myapp' }
        let(:params) { { entry: '+auto.master' } }

        it { is_expected.to contain_concat__fragment('autofs::add_master_entry myapp').with('content' => "+auto.master\n") }
      end

      context 'with custom order' do
        let(:title) { 'myapp' }
        let(:params) { { entry: '+dir:/etc/auto.master.d/myapp', order: 10 } }

        it { is_expected.to contain_concat__fragment('autofs::add_master_entry myapp').with('order' => '10') }
      end

      context 'with ensure_dir => true' do
        let(:title) { 'myapp' }
        let(:params) { { entry: '+dir:/etc/auto.master.d/myapp', ensure_dir: true } }

        it do
          # The +dir: prefix must be stripped to get the directory to create.
          is_expected.to contain_autofs__mapdir('myapp')
            .with_path('/etc/auto.master.d/myapp')
          is_expected.to contain_file('/etc/auto.master.d/myapp')
            .with(
              'ensure' => 'directory',
              'owner' => 'root',
              'group' => group,
              'mode' => '0755',
            )
          is_expected.to contain_concat__fragment('autofs::add_master_entry myapp')
            .that_requires('Autofs::Mapdir[myapp]')
            .that_requires('File[/etc/auto.master.d/myapp]')
        end
      end

      context 'with custom master map path' do
        let(:title) { 'myapp' }
        let(:params) { { entry: '+dir:/etc/auto.master.d/myapp', master: '/etc/auto.master.custom' } }

        it do
          is_expected.to contain_concat__fragment('autofs::add_master_entry myapp')
            .with('target' => '/etc/auto.master.custom')
        end
      end

      # README example: the +dir: line as the title, with ensure_dir => true.
      # The title is used verbatim as both the entry and the mapdir resource name.
      context 'with a +dir: title and ensure_dir => true' do
        let(:title) { '+dir:/etc/auto.master.d/myapp' }
        let(:params) { { ensure_dir: true } }

        it do
          # The fragment depends on the mapdir, which is what ensures the
          # directory exists before the drop-in line is read by automount.
          is_expected.to contain_autofs__mapdir('+dir:/etc/auto.master.d/myapp')
            .with_path('/etc/auto.master.d/myapp')
          is_expected.to contain_file('/etc/auto.master.d/myapp')
            .with('ensure' => 'directory', 'owner' => 'root', 'group' => group, 'mode' => '0755')
          is_expected.to contain_concat__fragment('autofs::add_master_entry +dir:/etc/auto.master.d/myapp')
            .with('target' => master_map_file, 'content' => "+dir:/etc/auto.master.d/myapp\n")
            .that_requires('Autofs::Mapdir[+dir:/etc/auto.master.d/myapp]')
        end
      end

      # README example: a non-+dir: entry (NIS +auto.master) renders as-is and
      # pulls in no mapdir.
      context 'with a +auto.master NIS entry' do
        let(:title) { 'nis_maps' }
        let(:params) { { entry: '+auto.master' } }

        it do
          is_expected.to contain_concat__fragment('autofs::add_master_entry nis_maps')
            .with('target' => master_map_file, 'content' => "+auto.master\n")
          is_expected.not_to contain_autofs__mapdir('nis_maps')
        end
      end
    end
  end
end
