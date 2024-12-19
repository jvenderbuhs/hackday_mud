class CreateCharacters < ActiveRecord::Migration[7.0]
  def change
    create_table :characters do |t|
      t.string :name
      t.integer :profession, default: 0
      t.string :inventory_data, default: {}.to_json
      t.string :score, default: { lvl: 0, xp: 0, skill_points: 0, hp: 10, str: 0, dex: 0, weapon: nil, armor: nil, shield: nil }.to_json
      t.string :current_room, default: "Lobby"
      t.string :password
      t.string :session
    end
  end
end
