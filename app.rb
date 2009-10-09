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

def find_job(id)
  job = Job.find_by_id(params[:id])
  raise Sinatra::NotFound unless job
  job
end

post "/jobs" do
  config = Scheduler::Configuration.job(params[:name])
  job = Job.process(params[:name], config, params[:arguments])
  status(202)  # accepted
  job.id.to_s
end

put "/jobs/:id" do
  job = find_job(params[:id])
  job.update_attributes!(:state => params["state"], :message => params["message"])
  config = Scheduler::Configuration.job(job.name)
  params["state"] == "cancelled" && job.kill
  Job.run_queued_jobs(job.name, config)
  nil
end

get "/jobs/:id" do
  job = find_job(params[:id])
  return "#{job.state}: #{job.message}" if job.message
  job.state
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
    reap_children
    create!(:name => name, :state => "queued", :arguments => arguments)
  end
  
  def self.process(name, config, arguments)
    job = queue(name, arguments)
    if Job.can_run_now?(name, config["concurrent_limit"])
      job.run(config["command"])
    end
    job
  end
  
  def self.reap_children
    Process.wait(-1, Process::WNOHANG)
  rescue Errno::ECHILD
  end
  
  def self.run_queued_jobs(name, config)
    (config["concurrent_limit"] - running_jobs_count(name)).times do
      job = Job.find_by_name_and_state(name, "queued")
      break unless job
      job.run(config["command"])
    end
    reap_children
  end
  
  def run(command)
    pid = fork do
      exec("#{command} #{arguments}")
      exit!
    end
    update_attributes!(:state => "running", :pid => pid)
  end
  
  def kill
    Process.kill("TERM", pid)
  rescue Errno::ESRCH
  end
end
