require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "chef-rundeck"
    gem.summary = %Q{Integrates Chef with RunDeck}
    gem.description = %Q{Provides a resource endpoint for RunDeck from a Chef Server}
    gem.email = "adam@opscode.com"
    gem.homepage = "http://github.com/opscode/chef-rundeck"
    gem.authors = ["Adam Jacob"]
    gem.add_dependency "sinatra"
    gem.add_dependency "chef"
    gem.add_dependency "mixlib-cli"
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "yard", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core/rake_task'
ENV['TRAVIS_BUILD_DIR'] = "." unless ENV.has_key?('TRAVIS_BUILD_DIR')
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = [ '-I', 'lib', '-I', 'spec' ]
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.rspec_opts = [ '-I', 'lib', '-I', 'spec' ]
  spec.pattern = FileList['spec/**/*_spec.rb']
  spec.rcov = true
end

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
