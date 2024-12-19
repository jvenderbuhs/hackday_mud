class Character < ApplicationRecord
  broadcasts_to ->(character) { :characters }

  enum profession: {
    'Apprentice' => 0,
    'Barbarian' => 1
  }
end
