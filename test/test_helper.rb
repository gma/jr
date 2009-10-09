require "rubygems"
require "sinatra"
set :environment, :test

require 'test/unit'
require 'rack/test'
require 'mocha'
require 'shoulda'
require 'active_support/testing/assertions'

require File.join(File.dirname(__FILE__), *%w[.. app])

module SchedulerTest
  include Rack::Test::Methods
  include ActiveSupport::Testing::Assertions

  def app
    Sinatra::Application
  end
  
  def define_job(name, command, limit)
    test_file = "/tmp/scheduler-config.yml"
    Scheduler::Configuration.stubs(:file).returns(test_file)
    File.open(test_file, "w") do |file|
      file.write("#{name}:\n  command: #{command}\n  concurrent_limit: #{limit}")
    end
    [name, command, limit]
  end
end
