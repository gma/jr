module Scheduler
  class Configuration
    def self.database
      db_config = File.join(File.dirname(__FILE__), *%w[.. config database.yml])
      config = YAML.load(ERB.new(IO.read(db_config)).result)
      config[Sinatra::Application.environment.to_s].symbolize_keys
    end
  end
end
