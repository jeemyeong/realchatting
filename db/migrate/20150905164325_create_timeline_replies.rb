class CreateTimelineReplies < ActiveRecord::Migration
  def change
    create_table :timeline_replies do |t|

      t.integer :user_id
      t.integer :channel_id
      t.integer :timeline_id
      t.string :reply
      t.timestamps null: false
    end
  end
end
