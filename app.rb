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

post '/jobs' do
  job = Job.create!(:state => "running")
  command = Scheduler::Configuration.command(params[:name])
  system("#{command} #{params[:arguments]}")
  job.id.to_s
end

class Job < ActiveRecord::Base
end