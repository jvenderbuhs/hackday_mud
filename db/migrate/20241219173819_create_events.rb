class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.references :character, type: :id, foreign_key: true
      t.string :room
      t.string :info

      t.timestamps
    end
  end
end
