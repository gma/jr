require File.join(File.dirname(__FILE__), "test_helper")

class ConfigurationTest < Test::Unit::TestCase
  include SchedulerTest
  
  context "Configuration" do
    setup do
      @name, @command = define_job("unskilled", "a command")
    end
    
    should "return the command to run for a job" do
      assert_equal @command, Scheduler::Configuration.command(@name)
    end
    
    should "raise if the job name doesn't exist in the configuration" do
      assert_raise RuntimeError do
        Scheduler::Configuration.command("holiday")
      end
    end
  end
end
