require "rake/testtask"
begin
  require "sinatra/activerecord/rake"
  require "app"
rescue LoadError
  unless ARGV.detect { |arg| arg == "gems:install" }
    $stderr.write("gem dependencies not met -- try rake gems:install\n")
  end
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/*_test.rb"
  t.verbose = true
end

namespace :gems do
  desc "Install dependencies (set RACK_ENV=test for tests)"
  task :install do
    if ENV["RACK_ENV"] == "test"
      GemInstaller.require_gem "mocha", :version => "0.9.7"
      GemInstaller.require_gem "rack-test", :version => "0.5.0"
      GemInstaller.require_gem "thoughtbot-shoulda", :version => "2.10.2",
                               :source => "http://gems.github.com"
    end
    GemInstaller.require_gem "sinatra", :version => "0.9.4"
    GemInstaller.require_gem "activerecord", :version => "2.3.4"
    GemInstaller.require_gem "sinatra-activerecord", 
                             :version => "0.1.2", 
                             :source => "http://gemcutter.org"
  end
end

class GemInstaller
  def self.require_gem(name, options)
    installed = if options.has_key?(:version)
      Gem.available?(name, options[:version])
    else
      Gem.available?(name)
    end
    installed || install(name, options)
  end
  
  def self.install(name, options)
    $stdout.sync = true
    cmd = "gem install " << name
    cmd << " --version #{options[:version]}" if options[:version]
    cmd << " --source #{options[:source]}" if options[:source]
    puts cmd
    system(cmd)
  end
end