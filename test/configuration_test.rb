require File.join(File.dirname(__FILE__), "test_helper")

class ConfigurationTest < Test::Unit::TestCase
  include SchedulerTest
  
  context "Configuration" do
    setup do
      @name, @command, @limit = define_job("unskilled", "a command", 5)
    end
    
    should "return the command to run for a job" do
      assert_equal @command, Scheduler::Configuration.command(@name)
    end
    
    should "return the max number of concurrent commands for a job" do
      assert_equal @limit, Scheduler::Configuration.concurrent_limit(@name)
    end    
    
    should "raise if the job name doesn't exist in the configuration" do
      assert_raise RuntimeError do
        Scheduler::Configuration.command("holiday")
      end
    end
    
    should "raise if a job setting doesn't exist in the configuration" do
      assert_raise RuntimeError do
        Scheduler::Configuration.job_setting(@name, "bad setting")
      end
    end
  end
end
