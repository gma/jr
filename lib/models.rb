require "sinatra/activerecord"

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
    else
      count = count(:conditions => ["name = ? AND state = 'queued'", name])
      log.warn "Concurrent #{name} limit reached: " + \
          "#{config["concurrent_limit"]} running, #{count} queued"
      log.info "Queued #{name} job: #{job.id}"
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
      if job
        log.info "Running a pending #{job.name} job"
        job.run(config["command"])
      end
    end
    reap_children
  end
  
  def run(command)
    log.info "Running #{name} job: #{id}"
    pid = fork do
      exec("#{command} #{arguments}")
      exit!
    end
    update_attributes!(:state => "running", :pid => pid)
  end
  
  def kill
    log.info "Killing process: #{pid}"
    Process.kill("TERM", pid)
  rescue Errno::ESRCH
  end
end
