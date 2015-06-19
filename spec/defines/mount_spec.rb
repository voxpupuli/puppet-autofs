require 'spec_helper'
describe 'autofs::mount', :type => :define do
  let(:title) { 'auto.home' }

  let(:facts) do
    {
      :concat_basedir => '/etc'
    }
  end

  let(:params) do
    {
        :mount => '/home',
        :mapfile => '/etc/auto.home',
        :mapcontents => 'test',
        :options => '--timeout=120',
        :order => '01'
    }
  end

  context 'with default parameters' do

    it do
      should contain_concat__fragment('autofs::fragment preamble /home').with('target' => '/etc/auto.master')
    end

    it do
      should contain_file('/home').with('ensure' => 'directory')
    end

    it do
      should contain_file('/etc/auto.home').with(
        'ensure' => 'present',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644'
      )
    end
  end


end