require File.join(File.dirname(__FILE__), *%w[.. app])
require 'test/unit'
require 'rack/test'
require 'shoulda'

set :environment, :test

class SchedulerTest < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end

  context "GET /jobs/123" do
    should "return not found if job doesn't exist" do
      get "/jobs/123"
      assert last_response.not_found?
    end
  end
  
end