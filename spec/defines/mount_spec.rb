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
        :mapcontents => %W( test foo bar ),
        :options => '--timeout=120',
        :order => '01'
    }
  end

  context 'with default parameters' do

    it do
      should contain_concat__fragment('autofs::fragment preamble /home').with('target' => '/etc/auto.master')
    end

#    it do
#      should contain_file('/home').with('ensure' => 'directory')
#    end

    it do
      should contain_file('/etc/auto.home').with(
        'ensure' => 'present',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644'
      )
    end
  end

  context 'with indirect map' do
    let(:params) do
      {
        :mount       => '/home',
        :mapfile     => '/etc/auto.home',
        :mapcontents => %W( test foo bar ),
        :options     => '--timeout=120',
        :order       => '01',
        :direct      => false
      }
    end

    it do
      should_not contain_file('/home').with('ensure' => 'directory')
    end
  end

  context 'with executable map' do
    let(:params) do
      {
        :mount       => '/home',
        :mapfile     => '/etc/auto.home',
        :mapcontents => %W( test foo bar ),
        :options     => '--timeout=120',
        :order       => '01',
        :execute     => true
      }
    end

    it do
      should contain_file('/etc/auto.home').with('mode' => '0755')
    end
  end



end
