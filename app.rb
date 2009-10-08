require "logger"
require "yaml"
require "erb"

require "rubygems"
require "sinatra"
require "sinatra/activerecord"
require File.join(File.dirname(__FILE__), *%w[lib configuration])

ActiveRecord::Base.establish_connection(Scheduler::Configuration.database)

log = Logger.new(STDOUT)
log.level = Logger::DEBUG

class Job < ActiveRecord::Base
end