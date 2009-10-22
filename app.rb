require "logger"
require "yaml"
require "erb"

require "rubygems"
require "sinatra"
require "lib/configuration"
require "lib/models"
require "lib/database"

def log
  if ! @logger
    file = "#{File.dirname(__FILE__)}/log/#{Sinatra::Base.environment}.log"
    @logger = Logger.new(file, "daily")
    @logger.level = Sinatra::Base.production? ? Logger::INFO : Logger::DEBUG
    
    # We need a new formatter as ActiveSupport overrides the Ruby default
    # (the dirty little bitch).
    @logger.formatter = Logger::Formatter.new
    @logger.datetime_format = "%b %d %H:%M:%S"
  end
  @logger
end

def log_params(*names)
  names.map { |name| "#{name}='#{params[name.to_s]}'" }.join(", ")
end

def find_job
  job = Job.find_by_id(params[:id])
  raise Sinatra::NotFound unless job
  job
end

def find_running_job_by_pid
  job = Job.find_by_state_and_pid("running", params[:pid])
  raise Sinatra::NotFound unless job
  job
end

def update_job(job)
  log.info %Q{Updating job: #{job.id}, #{log_params(:state, :message)}}
  job.update_attributes!(:state => params["state"], :message => params["message"])
  if params["state"] == "cancelled"
    log.info "Job cancelled: #{job.id}"
    job.kill
  end
  config = JobRunner::Configuration.job(job.name)
  Job.run_queued_jobs(job.name, config)
  nil
end

log.info "Starting up"

post "/jobs/?" do
  begin
    config = JobRunner::Configuration.job(params[:name])
    job = Job.process(params[:name], config, params[:arguments])
    status(202)  # accepted
    job.id.to_s
  rescue JobRunner::JobNotFoundError => exception
    log.error "Exception caught: #{exception}"
  end
end

put "/jobs/:id" do
  update_job(find_job)
end

put "/jobs/pid/:pid" do
  update_job(find_running_job_by_pid)
end

get "/jobs/:id" do
  job = find_job
  response = job.message ? "#{job.state}: #{job.message}" : job.state
  log.info "Checked state of job #{job.id}: #{response}"
  response
end
