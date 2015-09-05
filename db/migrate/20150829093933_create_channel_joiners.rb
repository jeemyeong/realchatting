class CreateChannelJoiners < ActiveRecord::Migration
  def change
    create_table :channel_joiners do |t|

      t.integer :channel_id #채널
      t.integer :user_id #유져
      t.integer :guest_id #게스트
  
      t.timestamps null: false
    end
  end
end
