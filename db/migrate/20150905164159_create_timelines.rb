class CreateTimelines < ActiveRecord::Migration
  def change
    create_table :timelines do |t|

      t.integer :user_id
      t.integer :channel_id
      t.string :title
      t.string :text
      t.string :button
      t.string :button_color
      t.string :image
      
      t.timestamps null: false
    end
  end
end
