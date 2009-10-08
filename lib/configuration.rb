module Scheduler
  class Configuration
    def self.load_yaml(file)
      YAML.load(ERB.new(IO.read(file)).result)
    end
    
    def self.database
      db_config = File.join(File.dirname(__FILE__), *%w[.. config database.yml])
      load_yaml(db_config)[Sinatra::Application.environment.to_s].symbolize_keys
    end
    
    def self.file
      File.join(File.dirname(__FILE__), *%w[.. config config.yml])
    end
    
    def self.command(name)
      job_setting(name, "command")
    end
    
    def self.concurrent_limit(name)
      job_setting(name, "concurrent_limit")
    end
    
    def self.job_setting(name, setting)
      jobs = load_yaml(file)
      unless jobs.has_key?(name) && jobs[name].has_key?(setting)
        raise "job not found: #{name}" 
      end
      jobs[name][setting]
    end
  end
end
