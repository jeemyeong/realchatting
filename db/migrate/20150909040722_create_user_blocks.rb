class CreateUserBlocks < ActiveRecord::Migration
  def change
    create_table :user_blocks do |t|
      t.integer :user_id
      t.integer :block_user_id
      t.integer :block_guest_id
      t.timestamps null: false
    end
  end
end
