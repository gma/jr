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
    @command_output = "/tmp/scheduler-test-output"
    @command_pid = "/tmp/scheduler-command.pid"
    FileUtils.rm_f(@command_output)
    FileUtils.rm_f(@command_pid)
    @name, @command, @limit = define_job(
        "unskilled", File.join(File.dirname(__FILE__), "mock_command"), 2)
  end

  def do_post(args = {})
    options = { :wait => true }.merge(args)
    post "/jobs", { :name => "unskilled", :arguments => "role=burger-flipper" }
    Process.wait if options[:wait]
  end
  
  context "POST /jobs" do
    should "create a new job with state running" do
      assert_difference("Job.count") { do_post }
    end
    
    should "return status 202 accepted" do
      do_post
      assert_equal 202, last_response.status
    end
    
    should "return the job id" do
      do_post
      assert_equal Job.last.id.to_s, last_response.body
    end
    
    should "run the command" do
      do_post
      assert_equal "role=burger-flipper", File.open(@command_output).read.chomp
    end
    
    should "store the pid of the command" do
      do_post
      assert_equal File.open(@command_pid).read.chomp.to_i, Job.last.pid
    end

    context "when concurrent limit reached" do
      setup do
        @limit.times { do_post }
        do_post(:wait => false)
      end

      should "queue a job" do
        assert_equal "queued", Job.last.state
      end
      
      should "store a queued job's arguments" do
        assert_equal "role=burger-flipper", Job.last.arguments
      end
    end
  end

  context "PUT /jobs/123" do
    setup do
      do_post
      @job = Job.last
    end
    
    should "return not found if job doesn't exist" do
      put "/jobs/#{@job.id + 1}", { :state => "complete" }
      assert last_response.not_found?
    end
    
    should "update the job's state to complete" do
      put "/jobs/#{@job.id}", { :state => "complete" }
      assert last_response.ok?
      assert_equal "complete", Job.find(@job.id).state
    end
    
    context "when script sends an error message" do
      should "store the error" do
        put "/jobs/#{@job.id}", :state => "error", :message => "Borked"
        @job.reload
        assert_equal "error", @job.state
        assert_equal "Borked", @job.message
      end
    end
    
    context "when jobs queued and job completes" do
      should "run a queued job" do
        @limit.times { do_post(:wait => false) }
        put "/jobs/#{Job.first.id}", :state => "complete"
        assert_equal "running", Job.last.state
      end
    end
  end

  context "GET /jobs/123" do
    setup do
      do_post
      @job = Job.last
    end
    
    should "return not found if job doesn't exist" do
      get "/jobs/#{@job.id + 1}"
      assert last_response.not_found?
    end
    
    should "return the job status" do
      get "/jobs/#{@job.id}"
      assert_equal "running", last_response.body
    end
    
    context "when job has a message" do
      setup do
        @message = "sorted"
        @job.update_attributes!(:state => "complete", :message => @message)
      end
      
      should "return the job's message" do
        get "/jobs/#{@job.id}"
        assert_equal "complete: #{@message}", last_response.body
      end
    end
  end  
end
