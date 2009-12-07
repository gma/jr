require File.join(File.dirname(__FILE__), "test_helper")
require File.join(File.dirname(__FILE__), *%w[.. lib configuration])

class ConfigurationTest < Test::Unit::TestCase
  include JobRunnerTest
  
  context "Configuration" do
    should "return the command and concurrent limit for a job" do
      name, command, limit = define_job("unskilled", "a command", 5)
      assert_equal(
          { "command" => command, "concurrent_limit" => limit }, 
          JobRunner::Configuration.job(name))
    end
    
    should "raise if the job name doesn't exist in the configuration" do
      define_job("unskilled", "a command", 5)
      assert_raise JobRunner::JobNotFoundError do
        JobRunner::Configuration.job("holiday")
      end
    end

    should "raise if no jobs exist in the configuration" do
      assert_raise JobRunner::JobNotFoundError do
        JobRunner::Configuration.job("holiday")
      end
    end
    
    should "consider hoptoad API key to be nil if not set" do
      assert_nil JobRunner::Configuration.hoptoad_key
    end
    
    should "return the hoptoad API key if set" do
      define_hoptoad_key("pretend-key")
      assert_equal "pretend-key", JobRunner::Configuration.hoptoad_key
    end
  end
end
