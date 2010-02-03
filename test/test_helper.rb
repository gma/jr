require File.join(File.dirname(__FILE__), *%w[.. vendor gems environment])
require "sinatra"
set :environment, :test

require "test/unit"
require "rack/test"
require "mocha"
require "shoulda"
require "active_support/testing/assertions"

class Logger
  def add(*args)
    # Silence the logger during testing
  end
end

module JobRunnerTest
  include Rack::Test::Methods
  include ActiveSupport::Testing::Assertions

  def app
    Sinatra::Application
  end
  
  def define_job(name, command, limit)
    test_file = "/tmp/jr-config.yml"
    JobRunner::Configuration.stubs(:file).returns(test_file)
    File.open(test_file, "w") do |file|
      file.write <<-EOF
jobs:
  #{name}:
    command: #{command}
    concurrent_limit: #{limit}
      EOF
    end
    [name, command, limit]
  end
  
  def define_hoptoad_key(key)
    test_file = "/tmp/jr-config.yml"
    JobRunner::Configuration.stubs(:file).returns(test_file)
    File.open(test_file, "w") do |file|
      file.write <<-EOF
hoptoad_key:
  #{key}
      EOF
    end
  end
end
