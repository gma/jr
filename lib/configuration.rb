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
      jobs = load_yaml(file)
      raise "job not found: #{name}" unless jobs.has_key?(name)
      jobs[name]
    end
  end
end
