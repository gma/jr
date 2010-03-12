begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

require "logger"
require "yaml"
require "erb"

require "sinatra"

require File.join(File.dirname(__FILE__), *%w[lib configuration])
require File.join(File.dirname(__FILE__), *%w[lib models])
require File.join(File.dirname(__FILE__), *%w[lib database])

set :lock, true

def log_error_to_hoptoad(error)
  begin
    require "toadhopper"
    Toadhopper.api_key = JobRunner::Configuration.hoptoad_key
    Toadhopper.post!(error)
  rescue LoadError
  end
end

helpers do
  def log_errors
    begin
      yield
    rescue SystemExit
      raise
    rescue Exception => error
      log_error_to_hoptoad(error)
      log.error("#{request.request_method} #{request.path} raised #{error}")
      raise
    end
  end
end

def log
  if ! @logger
    file = "#{File.dirname(__FILE__)}/log/#{Sinatra::Base.environment}.log"
    begin
      @logger = Logger.new(file, "daily")
    rescue Logger::ShiftingError  # yesterday's file exists
      @logger = Logger.new(file)
    end
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
  Job.find_by_id(params[:id]) || raise(Sinatra::NotFound)
end

def find_running_job_by_pid
  Job.find_by_state_and_pid("running", params[:pid]) || raise(Sinatra::NotFound)
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

class ProcessFinder
  def self.process_running?(pid)
    ! %x{ps | awk '{ print $1 }' | grep #{pid}}.blank?
  end
end

def mark_dangling_jobs_complete
  Job.find_all_by_state("running").each do |job|
    if ! ProcessFinder.process_running?(job.pid)
      log.warn("Marking dangling job complete: #{job.id} (pid was #{job.pid})")
      job.update_attributes!(:state => "complete")
    end
  end
end

log.info "Starting up"

post "/jobs/?" do
  log_errors do
    begin
      config = JobRunner::Configuration.job(params[:name])
      job = Job.process(params[:name], config, params[:arguments])
      status(202)  # accepted
      job.id.to_s
    rescue JobRunner::JobNotFoundError => exception
      log.error "Exception caught: #{exception}"
    end
  end
end

put "/jobs/:id" do
  log_errors { update_job(find_job) }
end

put "/jobs/pid/:pid" do
  log_errors { update_job(find_running_job_by_pid) }
end

get "/jobs/:id" do
  log_errors do
    mark_dangling_jobs_complete
    job = find_job
    response = job.message ? "#{job.state}: #{job.message}" : job.state
    log.info "Checked state of job #{job.id}: #{response}"
    response
  end
end
