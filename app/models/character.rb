class Character < ApplicationRecord
  broadcasts_to ->(character) { :characters }
  validates :name, presence: true
  validates :password, presence: true

  enum profession: {
    'Apprentice' => 0,
    'Barbarian' => 1
  }
end
