require "rubygems"
require "sinatra"
require "sinatra/activerecord"
require "yaml"
require "erb"
require File.join(File.dirname(__FILE__), *%w[lib configuration])

ActiveRecord::Base.establish_connection(Scheduler::Configuration.database)
