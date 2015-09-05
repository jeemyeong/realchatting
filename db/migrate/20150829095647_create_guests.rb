class CreateGuests < ActiveRecord::Migration
  def change
    create_table :guests do |t|
      t.string :ip_address
      t.timestamps null: false
    end
  end
end
