module Scheduler
  class JobNotFoundError < RuntimeError; end
  
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
    
    def self.job(name)
      jobs = load_yaml(file)
      jobs[name] or raise JobNotFoundError.new("job not found: #{name}") 
    end
  end
end
