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

      t.boolean :monday, default: false
      t.boolean :tuesday, default: false
      t.boolean :wednesday, default: false
      t.boolean :thursday, default: false
      t.boolean :friday, default: false
      t.boolean :saturday, default: false
      t.boolean :sunday, default: false
      
      t.timestamps null: false
    end
  end
end
