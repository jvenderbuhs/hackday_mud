class Event < ApplicationRecord
  broadcasts_to ->(event) { :events }
  belongs_to :character
  validates :room, presence: true
  validates :info, presence: true
end
