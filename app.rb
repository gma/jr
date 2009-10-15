require "logger"
require "yaml"
require "erb"

require "rubygems"
require "sinatra"
require File.join(File.dirname(__FILE__), *%w[lib configuration])
require File.join(File.dirname(__FILE__), *%w[lib models])
require File.join(File.dirname(__FILE__), *%w[lib database])

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG

def find_job(id)
  job = Job.find_by_id(params[:id])
  raise Sinatra::NotFound unless job
  job
end

def info(message)
  $log.info message
end

def warn(exception)
  $log.warn "WARNING: #{exception}"
end

def error(exception)
  $log.error "ERROR: #{exception}"
end

post "/jobs" do
  $log.debug "Received request to run a '#{params[:name]}' job"
  begin
    config = JobRunner::Configuration.job(params[:name])
    info "Starting job: '#{params[:name]}', arguments='#{params[:arguments]}'"
    job = Job.process(params[:name], config, params[:arguments])
    status(202)  # accepted
    job.id.to_s
  rescue JobRunner::JobNotFoundError => exception
    warn(exception)
  end
end

put "/jobs/:id" do
  job = find_job(params[:id])
  job.update_attributes!(:state => params["state"], :message => params["message"])
  config = JobRunner::Configuration.job(job.name)
  params["state"] == "cancelled" && job.kill
  Job.run_queued_jobs(job.name, config)
  nil
end

get "/jobs/:id" do
  job = find_job(params[:id])
  return "#{job.state}: #{job.message}" if job.message
  job.state
end
