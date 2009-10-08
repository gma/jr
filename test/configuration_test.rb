require File.join(File.dirname(__FILE__), "test_helper")

class ConfigurationTest < Test::Unit::TestCase
  include SchedulerTest
  
  context "Configuration" do
    setup do
      @name, @command, @limit = define_job("unskilled", "a command", 5)
    end
    
    should "return the command and concurrent limit for a job" do
      assert_equal(
          { "command" => @command, "concurrent_limit" => @limit }, 
          Scheduler::Configuration.job(@name))
    end
    
    should "raise if the job name doesn't exist in the configuration" do
      assert_raise RuntimeError do
        Scheduler::Configuration.job("holiday")
      end
    end
  end
end
