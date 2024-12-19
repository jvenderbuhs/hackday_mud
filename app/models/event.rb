class Event < ApplicationRecord
  broadcasts_to ->(event) { "events_#{ event.room }" }
  belongs_to :character
  validates :room, presence: true
  validates :info, presence: true

  ROOMS = {
    'Lobby' => {
      neighbours: [],
      description: 'Welcome to HackMUD, this is a staging area to check out commands before you are thrust into the world. ' \
                   'When you are ready to explore enter: "move valley".'
    },
    'Valley' => {
      neighbours: ['Lobby', 'Forest'],
      description: 'You are in a lush valley with a few boars wandering around. ' \
                   'On the edge of the valley you notice a dark "forest".'
    },
    'Forest' => {
      neighbours: ['Valley', 'Manor'],
      description: 'You are in a dark forest, spider-webs span between the trees that slow your advance. ' \
                   'Behind you is a delightful "valley" and further down the trail you can barely make out a "manor".'
    },
    'Manor' => {
      neighbours: ['Forest'],
      description: 'The Manor is locked but the grounds provide a quaint little graveyard for you to explore. '\
                   'This appears to be a dead-end with the only option going back into the "forest".'
    }
  }

  class << self
    def handle_command(character, unparsed_command)
      command, message = unparsed_command.split(' ', 2)

      case command
      when 'say'
        say(character, message)
      when 'look'
        look(character)
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

    def look(character)
      Event.create(
        character: character,
        room: character.current_room,
        info: ROOMS[character.current_room][:description],
        personal: true
      )
    end

    def move(character, room)
      room = room.titleize
      if ROOMS.keys.include?(room) && ROOMS[room][:neighbours].include?(character.current_room)
        old_room = character.current_room
        character.update(current_room: room)
        Event.create(
          character: character,
          room: old_room,
          info: "left the '#{ character.current_room } to explore the '#{ room }'."
        )
        Event.create(
          character: character,
          room: room,
          info: "entered the '#{ room }' coming from the '#{ old_room }'."
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
