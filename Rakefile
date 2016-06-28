require 'rubygems'
require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet_blacksmith/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.ignore_paths = %w{'spec/**/*.pp', 'pkg/**/*.pp'}

desc 'Validate manifests, templates, and ruby files'
task :deploy do
  Dir['spec/**/*.rb','lib/**/*.rb'].each do |ruby_file|
    sh "ruby -c #{ruby_file}" unless ruby_file =~ /spec\/fixtures/
  end
  Rake::Task[:release_checks].invoke
  Rake::Task['module:release'].invoke
end
