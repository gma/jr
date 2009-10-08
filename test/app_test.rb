require "rubygems"
require "sinatra"

set :environment, :test

require 'test/unit'
require 'rack/test'
require 'shoulda'
require 'rake'
require 'sinatra/activerecord/rake'
require 'active_support/testing/assertions'

require File.join(File.dirname(__FILE__), *%w[.. app])

class NullLogger
  def method_missing(*args)
  end
end

class SchedulerTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include ActiveSupport::Testing::Assertions
  
  def app
    Sinatra::Application
  end
  
  def reset_database
    ActiveRecord::Base.logger = NullLogger.new
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Migrator.migrate('db/migrate', 0)
    ActiveRecord::Migrator.migrate('db/migrate', nil)
  end

  def setup
    reset_database
  end

  context "POST /jobs" do
    should "create a new job with state running" do
      assert_difference "Job.count" do
        post "/jobs", :type => "unskilled"
      end
    end
  end

  context "GET /jobs/123" do
    should "return not found if job doesn't exist" do
      get "/jobs/123"
      assert last_response.not_found?
    end
  end
  
end