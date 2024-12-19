class Character < ApplicationRecord
  broadcasts_to ->(character) { :characters }
  broadcasts_to ->(player) { :players }, partial: "characters/player"
  validates :name, presence: true
  validates :password, presence: true

  enum profession: {
    'Apprentice' => 0,
    'Barbarian' => 1
  }
end
