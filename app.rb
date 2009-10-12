require "logger"
require "yaml"
require "erb"

require "rubygems"
require "sinatra"
require File.join(File.dirname(__FILE__), *%w[lib configuration])
require File.join(File.dirname(__FILE__), *%w[lib models])

log = Logger.new(STDOUT)
log.level = Logger::DEBUG

ActiveRecord::Base.establish_connection(Scheduler::Configuration.database)

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
