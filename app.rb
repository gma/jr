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

post "/jobs" do
  config = Scheduler::Configuration.job(params[:name])
  job = Job.process(params[:name], config, params[:arguments])
  status(202)  # accepted
  job.id.to_s
end

put "/jobs/:id" do
  job = Job.find_by_id(params[:id])
  raise Sinatra::NotFound unless job
  job.update_attributes!(:state => params["state"], :message => params["message"])
  config = Scheduler::Configuration.job(job.name)
  Job.run_queued_jobs(job.name, config)
  nil
end

class Job < ActiveRecord::Base
  validates_presence_of :name, :state

  def self.running_jobs_count(name)
    count(:conditions => ["name = ? and state = 'running'", name])
  end
  
  def self.can_run_now?(name, limit)
    running_jobs_count(name) < limit
  end
  
  def self.queue(name, arguments)
    self.create!(:name => name, :state => "queued", :arguments => arguments)
  end
  
  def self.process(name, config, arguments)
    job = queue(name, arguments)
    if Job.can_run_now?(name, config["concurrent_limit"])
      job.run(config["command"])
    end
    job
  end
  
  def self.run_queued_jobs(name, config)
    (config["concurrent_limit"] - running_jobs_count(name)).times do
      job = Job.find_by_name_and_state(name, "queued")
      break unless job
      job.run(config["command"])
    end
    Process.waitall
  end
  
  def run(command)
    pid = fork do
      exec("#{command} #{arguments}")
      exit!
    end
    update_attributes!(:state => "running", :pid => pid)
  end
end