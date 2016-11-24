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
        :mount       => '/home',
        :mapfile     => '/etc/auto.home',
        :mapcontents => %W( test foo bar ),
        :options     => '--timeout=120',
        :order       => 01,
        :master      => '/etc/auto.master'
    }
  end

  context 'with default parameters' do

    it do
      should contain_concat('/etc/auto.master')
      should contain_concat__fragment('autofs::fragment preamble /home /etc/auto.home').with('target' => '/etc/auto.master')
    end

    it do
      should contain_file('/etc/auto.home').with(
        'ensure' => 'present',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0644'
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
        :order       => 01,
        :direct      => false
      }
    end

    it do
      should_not contain_file('/home').with('ensure' => 'directory')
    end
  end

  context 'with direct map' do
    let(:params) do
      {
        :mount       => '/-',
        :mapfile     => '/etc/auto.home',
        :mapcontents => [ '/home /test', '/home /foo', '/home /bar'],
        :options     => '--timeout=120',
        :order       => 01,
        :direct      => true
      }
    end

    it do
      should contain_concat__fragment('autofs::fragment preamble /- /etc/auto.home')
    end
  end

  context 'with EL7 directory' do
    let(:params) do
      {
        :name        => 'home',
        :mount       => '/home',
        :mapfile     => '/etc/auto.home',
        :mapcontents => %W( test foo bar ),
        :options     => '--timeout=120',
        :order       => 01,
        :map_dir     => '/etc/auto.master.d',
        :use_dir     => true
      }
    end

    it do
      should contain_concat__fragment('autofs::fragment preamble map directory')
    end

    it do
      should contain_file('/etc/auto.master.d').with(
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0755'
      )

      should contain_file('/etc/auto.master.d/home.autofs').with(
        'ensure' => 'present',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0644'
      )

      should contain_file('/etc/auto.home').with(
        'ensure' => 'present',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0644'
      )
    end
  end


  context 'with executable map' do
    let (:params) do
      {
        :mount       => '/home',
        :mapfile     => '/etc/auto.home',
        :mapcontents => %W( test foo bar ),
        :options     => '--timeout=120',
        :order       => 01,
        :execute     => true
      }
    end

    it do
      should contain_file('/etc/auto.home').with('mode' => '0755')
    end
  end



end
