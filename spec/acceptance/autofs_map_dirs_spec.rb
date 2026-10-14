# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'autofs class with map_dirs' do
  def cleanup_helper
    pp = <<-EOS
      file { '/etc/auto.master': ensure => 'absent', }
    EOS
    apply_manifest(pp, catch_failures: true)
  end

  before(:context) { cleanup_helper }
  after(:context) { cleanup_helper }

  it 'enables drop-in directories without declaring mounts' do
    pp = <<-EOS
      class { 'autofs':
        map_dirs => ['/etc/auto.master.d', '/etc/auto.master.d.site'],
      }
    EOS

    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_changes: true)
  end

  describe file('/etc/auto.master') do
    its(:content) { is_expected.to match %r{^\+dir:/etc/auto\.master\.d\s*$} }
    its(:content) { is_expected.to match %r{^\+dir:/etc/auto\.master\.d\.site\s*$} }
  end
end
