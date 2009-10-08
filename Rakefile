require 'app'
require 'sinatra/activerecord/rake'

Rake.clear_tasks("db:migrate")

namespace :db do
  desc "migrate your database"
  task :migrate do
    if ActiveRecord::Migrator.current_version != ENV["VERSION"].to_i
      ActiveRecord::Migrator.migrate(
        'db/migrate', 
        ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      )
    end
  end
end
