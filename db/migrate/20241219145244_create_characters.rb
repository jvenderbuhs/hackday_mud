class CreateCharacters < ActiveRecord::Migration[7.0]
  def change
    create_table :characters do |t|
      t.string :name
      t.integer :profession, default: 0
      t.string :inventory_data, default: '{}'
      t.string :score, default: '{}'
      t.string :current_room, default: "Lobby"
      t.string :password
      t.string :session
    end
  end
end
