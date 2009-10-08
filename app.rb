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

config = Scheduler::Configuration

post "/jobs" do
  name = params[:name]
  if Job.reached_concurrent_limit?(name, config.concurrent_limit(name))
    job = Job.create!(:name => name, :state => "queued")
  else
    pid = fork do
      exec("#{config.command(name)} #{params[:arguments]}")
      exit!
    end
    job = Job.create!(:name => name, :state => "running", :pid => pid)
  end
  job.id.to_s
end

class Job < ActiveRecord::Base
  validates_presence_of :name, :state

  def self.reached_concurrent_limit?(name, limit)
    count(:conditions => ["name = ?", name]) >= limit
  end
end