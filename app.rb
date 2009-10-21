require "logger"
require "yaml"
require "erb"

require "rubygems"
require "sinatra"
require File.join(File.dirname(__FILE__), *%w[lib configuration])
require File.join(File.dirname(__FILE__), *%w[lib models])
require File.join(File.dirname(__FILE__), *%w[lib database])

def logger
  filename = "#{Sinatra::Base.environment}.log"
  log_dir = File.join(File.dirname(__FILE__), "log")
  FileUtils.mkdir_p(log_dir)
  log = Logger.new(File.join(log_dir, filename))
  log.level = Sinatra::Base.production? ? Logger::INFO : Logger::DEBUG
  log
end

$log = logger

def info(message)
  $log.info message
end

def warn(exception)
  $log.warn "WARNING: #{exception}"
end

def error(exception)
  $log.error "ERROR: #{exception}"
end

def find_job
  job = Job.find_by_id(params[:id])
  raise Sinatra::NotFound unless job
  job
end

def find_job_by_pid
  job = Job.find_by_pid(params[:pid])
  raise Sinatra::NotFound unless job
  job
end

def update_job(job)
  job.update_attributes!(:state => params["state"], :message => params["message"])
  params["state"] == "cancelled" && job.kill
  config = JobRunner::Configuration.job(job.name)
  Job.run_queued_jobs(job.name, config)
  nil
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
  update_job(find_job)
end

put "/jobs/pid/:pid" do
  update_job(find_job_by_pid)
end

get "/jobs/:id" do
  job = find_job
  return "#{job.state}: #{job.message}" if job.message
  job.state
end
