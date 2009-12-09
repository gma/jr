class IndexJobs < ActiveRecord::Migration
  def self.up
    add_index :jobs, [:name, :state], :name => "jobs_on_name_and_state_index"
    add_index :jobs, [:state, :pid], :name => "jobs_on_state_and_pid_index"
  end

  def self.down
    remove_index :jobs, :name => :jobs_on_name_and_state_index
    remove_index :jobs, :name => :jobs_on_state_and_pid_index
  end
end
