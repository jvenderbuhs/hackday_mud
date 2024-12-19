class Event < ApplicationRecord
  broadcasts_to ->(event) { :events }
  belongs_to :character
  validates :room, presence: true
  validates :info, presence: true

  class << self
    def handle_command(character, unparsed_command)
      command, message = unparsed_command.split(' ', 2)

      case command
      when 'say'
        say(character, message)
      when 'move'
        move(character, message)
      else
        say(character, "#{ command } #{ message }")
      end
    end

    def character_join(character)
      move(character, character.current_room)
    end

    private

    def say(character, message)
      Event.create(
        character: character,
        room: character.current_room,
        info: message
      )
    end

    def move(character, room)
      rooms = {
        'Lobby' => [],
        'Valley' => ['Lobby', 'Forest'],
        'Forest' => ['Valley', 'Manor'],
        'Manor' => ['Forest']
      }
      room = room.titleize

      if rooms.keys.include?(room) && rooms[room].include?(character.current_room)
        Event.create(
          character: character,
          room: room,
          info: "left the area '#{ character.current_room }'."
        )
        character.update(current_room: room)
        Event.create(
          character: character,
          room: room,
          info: "entered the area '#{ room }'."
        )
      elsif room == character.current_room
        Event.create(
          character: character,
          room: room,
          info: "entered the area '#{ room }'."
        )
      else
        Event.create(
          character: character,
          room: character.current_room,
          info: "tried to venture into the '#{ room }' but could not find it in the '#{ character.current_room }'."
        )
      end
    end
  end
end
