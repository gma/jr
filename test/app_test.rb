require File.join(File.dirname(__FILE__), *%w[.. app])
require 'test/unit'
require 'rack/test'
require 'shoulda'
require 'rake'
require 'sinatra/activerecord/rake'
require 'active_support/testing/assertions'

set :environment, :test

class SchedulerTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include ActiveSupport::Testing::Assertions
  
  def app
    Sinatra::Application
  end

  def setup
    ENV["VERSION"] = "0"
    Rake::Task["db:migrate"].invoke
    ENV.delete("VERSION")
    Rake::Task["db:migrate"].invoke
  end

  context "POST /jobs" do
    should_eventually "create a new job with state running" do
      assert_difference "Job.count" do
        post "/jobs"
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