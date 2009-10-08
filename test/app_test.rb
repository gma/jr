require File.join(File.dirname(__FILE__), "test_helper")
require "fileutils"

class AppTest < Test::Unit::TestCase
  include SchedulerTest
  
  def reset_database
    ActiveRecord::Base.logger = Logger.new(nil)
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Migrator.migrate('db/migrate', 0)
    ActiveRecord::Migrator.migrate('db/migrate', nil)
  end

  def setup
    reset_database
  end

  def valid_post_params
    { :name => "unskilled", :arguments => "role=burger-flipper" }
  end
  
  context "POST /jobs" do
    setup do
      @command_output = "/tmp/scheduler-test-output"
      @command_pid = "/tmp/scheduler-command.pid"
      FileUtils.rm_f(@command_output)
      FileUtils.rm_f(@command_pid)
      @name, @command, @limit = define_job(
          "unskilled", File.join(File.dirname(__FILE__), "mock_command"), 2)
    end
    
    should "create a new job with state running" do
      assert_difference("Job.count") { post "/jobs", valid_post_params }
    end
    
    should "return the job id" do
      post "/jobs", valid_post_params
      assert_equal Job.last.id.to_s, last_response.body
    end
    
    should "run the command" do
      post "/jobs", valid_post_params
      assert_equal "role=burger-flipper", File.open(@command_output).read.chomp
    end
    
    should "store the pid of the command" do
      post "/jobs", valid_post_params
      assert_equal File.open(@command_pid).read.chomp.to_i, Job.last.pid
    end
    
    should "queue a job when concurrent limit reached" do
      @limit.times { post "/jobs", valid_post_params }
      post "/jobs", valid_post_params
      assert_equal "queued", Job.last.state
    end
  end

  context "GET /jobs/123" do
    should "return not found if job doesn't exist" do
      get "/jobs/123"
      assert last_response.not_found?
    end
    
    should_eventually "clear up zombie processes" do
    end
  end  
end
