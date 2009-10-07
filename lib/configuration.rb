module Scheduler
  class Configuration
    def self.database
      environment = "development"
      config = YAML.load(ERB.new(IO.read("config/database.yml")).result)
      config[environment].symbolize_keys
    end
  end
end
