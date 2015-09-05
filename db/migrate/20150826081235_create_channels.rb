class CreateChannels < ActiveRecord::Migration
  def change
    create_table :channels do |t|

      t.integer :user_id, null: false #방장
      t.string :title, null: false #방의 이름
      t.string :image #방 이미지
      t.string :mediatype
      
      t.timestamps null: false
    end
  end
end
