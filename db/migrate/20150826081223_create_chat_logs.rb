class CreateChatLogs < ActiveRecord::Migration
  def change
    create_table :chat_logs do |t|

      t.integer :user_id
      t.integer :channel_id
      t.integer :guest_id
      t.text    :msg
      
      t.timestamps null: false
    end
  end
end
