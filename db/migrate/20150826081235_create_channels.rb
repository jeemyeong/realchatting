class CreateChannels < ActiveRecord::Migration
  def change
    create_table :channels do |t|

      t.integer :user_id, null: false #방장
      t.string :title, null: false #방의 이름
      t.string :image #방 이미지
      t.string :intro #방송 인트로
      t.string :link #방송 링크
      t.string :play #방송 동영상
      t.string :mediatype
      
      t.timestamps null: false
    end
  end
end
