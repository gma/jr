class CreateJobs < ActiveRecord::Migration
  def self.up
    create_table :jobs, :force => true do |t|
      t.string :name, :state
      t.integer :pid
      t.text :arguments, :message
      t.timestamps
    end
  end

  def self.down
    drop_table :jobs
  end
end
