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

namespace :db do
  desc "Create the database"
  task :create do
    environ = (ENV['RACK_ENV'] || 'development').downcase
    system "mysqladmin create jr_#{environ}"
  end
end
