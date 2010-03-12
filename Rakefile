require "app"
require "rake/testtask"
require "sinatra/activerecord/rake"

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
