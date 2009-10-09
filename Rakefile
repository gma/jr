require "rake/testtask"
require "sinatra/activerecord/rake"

require "app"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/*_test.rb"
  t.verbose = true
end
