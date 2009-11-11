require "fileutils"

require File.join(File.dirname(__FILE__), "test_helper")
require File.join(File.dirname(__FILE__), *%w[.. app])

class AppTest < Test::Unit::TestCase
  include JobRunnerTest
  
  def reset_database
    ActiveRecord::Base.logger = Logger.new(nil)
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Migrator.migrate('db/migrate', 0)
    ActiveRecord::Migrator.migrate('db/migrate', nil)
  end

  def setup
    reset_database
    @command_output = "/tmp/jr-test-output"
    @command_pid = "/tmp/jr-command.pid"
    FileUtils.rm_f(@command_output)
    FileUtils.rm_f(@command_pid)
    @name, @command, @limit = define_job(
        "unskilled", File.join(File.dirname(__FILE__), "mock_command"), 2)
  end

  def post_job(args = {})
    options = { :wait => true }.merge(args)
    post "/jobs", { :name => "unskilled", :arguments => "role=burger-flipper" }
    Process.wait if options[:wait]
  end
  
  def put_job(job, params = {})
    put "/jobs/#{job.id}", params
  end
  
  def put_job_pid(job, params = {})
    put "/jobs/pid/#{job.pid}", params
  end
  
  def get_job(job)
    get "/jobs/#{job.id}"
  end
  
  def timer(&block)
    start = Time.now
    yield
    Time.now - start
  end
  
  context "POST /jobs" do
    should "create a new job with state running" do
      assert_difference("Job.count") { post_job }
    end
    
    should "return status 202 accepted" do
      post_job
      assert_equal 202, last_response.status
    end
    
    should "return the job id" do
      post_job
      assert_equal Job.last.id.to_s, last_response.body
    end
    
    should "run the command" do
      post_job
      assert_equal "role=burger-flipper", File.open(@command_output).read.chomp
    end
    
    should "store the pid of the command" do
      post_job
      assert_equal File.open(@command_pid).read.chomp.to_i, Job.last.pid
    end

    context "when concurrent limit reached" do
      setup do
        @limit.times { post_job }
        post_job(:wait => false)
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
      post_job
      @job = Job.last
    end
    
    should "return not found if job doesn't exist" do
      put "/jobs/#{@job.id + 1}"
      assert last_response.not_found?
    end
    
    context "when the script sends complete" do
      should "update the job's state to complete" do
        put_job @job, :state => "complete"
        assert last_response.ok?
        assert_equal "complete", Job.find(@job.id).state
      end
    
      should "run queued jobs" do
        @limit.times { post_job(:wait => false) }
        put_job Job.first, :state => "complete"
        assert_equal "running", Job.last.state
      end
    end
    
    context "when the script sends an error message" do
      should "store the error" do
        put_job @job, :state => "error", :message => "Borked"
        @job.reload
        assert_equal "error", @job.state
        assert_equal "Borked", @job.message
      end
    end
    
    context "when the job is to be cancelled" do
      should "update the job's state to cancelled" do
        put_job @job, :state => "cancelled"
        assert_equal "cancelled", Job.find(@job.id).state
      end
      
      should "kill the job's script if it is running" do
        @name, @command, @limit = define_job("part-time", "sleep 30", 2)
        post "/jobs", :name => "part-time", :arguments => ""
        job = Job.last
        time_to_die = timer do
          put_job job, :state => "cancelled"
          Process.waitall
        end
        long_winded_unix_death = 5  # allows the process plenty of time to die
        assert time_to_die < long_winded_unix_death
      end
    end
  end

  context "PUT /jobs/pid/123" do
    setup do
      post_job
      @job = Job.last
    end

    should "have successful response if running job exists" do
      put_job_pid @job, :state => "complete"
      assert last_response.ok?
    end
    
    should "return not found unless job state is running" do
      @job.update_attribute(:state, "complete")
      put_job_pid @job, :state => "complete"
      assert last_response.not_found?
    end

    should "return not found if job doesn't exist" do
      put "/jobs/pid/#{@job.pid + 1}", :state => "complete"
      assert last_response.not_found?
    end
    
    context "when the script sends complete" do
      should "update the job's status to complete" do
        put_job_pid @job, :state => "complete"
        assert_equal "complete", Job.find(@job.id).state
      end

      should "run queued jobs" do
        @limit.times { post_job(:wait => false) }
        put_job_pid Job.first, :state => "complete"
        assert_equal "running", Job.last.state
      end
    end

    context "when the script sends an error message" do
      should "store the error" do
        put_job_pid @job, :state => "error", :message => "Borked"
        @job.reload
        assert_equal "error", @job.state
        assert_equal "Borked", @job.message
      end
    end
    
    context "when the job is to be cancelled" do
      should "update the job's state to cancelled" do
        put_job_pid @job, :state => "cancelled"
        assert_equal "cancelled", Job.find(@job.id).state
      end
      
      should "kill the job's script if it is running" do
        @name, @command, @limit = define_job("part-time", "sleep 30", 2)
        post "/jobs", :name => "part-time", :arguments => ""
        job = Job.last
        time_to_die = timer do
          put_job_pid job, :state => "cancelled"
          Process.waitall
        end
        long_winded_unix_death = 5  # allows the process plenty of time to die
        assert time_to_die < long_winded_unix_death
      end
    end
  end

  context "GET /jobs/123" do
    setup do
      @pid = 1234
      @state = "queued"
      @job = Job.create!(:name => "job", :state => @state, :pid => @pid)
    end
    
    should "return not found if job doesn't exist" do
      get "/jobs/#{@job.id + 1}"
      assert last_response.not_found?
    end
    
    should "return the job status" do
      get_job @job
      assert_equal @state, last_response.body
    end
    
    context "when job has a message" do
      setup do
        @message = "sorted"
        @job.update_attributes!(:state => @state, :message => @message)
      end
      
      should "return the job's state and message" do
        get_job @job
        assert_equal "#{@state}: #{@message}", last_response.body
      end
    end
    
    context "when job running" do
      setup do
        @job.update_attributes!(:state => "running")
      end
      
      should "mark running (but dead) jobs as complete" do
        ProcessFinder.stubs(:process_running?).returns(false)
        get_job @job
        @job.reload
        assert_equal "complete", @job.state
      end
      
      should "not mark jobs that are still running as complete" do
        ProcessFinder.stubs(:process_running?).returns(true)
        get_job @job
        @job.reload
        assert_equal "running", @job.state
      end
    end
  end  
end
