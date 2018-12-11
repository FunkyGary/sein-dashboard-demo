class AddFbData < ActiveRecord::Migration[5.1]
  def change
    create_table :fb_post_dbs do |t|
      t.datetime :created_time
      t.string :message
      t.integer :like
      t.integer :comment
      t.integer :share
      t.integer :interact
      
      t.timestamps
    end
  end
end
