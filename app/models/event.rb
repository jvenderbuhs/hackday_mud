class Event < ApplicationRecord
  broadcasts_to ->(event) { "events_#{ event.room }" }
  belongs_to :character
  validates :room, presence: true
  validates :info, presence: true

  ROOMS = {
    'Lobby' => {
      neighbours: [],
      description: 'Welcome to HackMUD, this is a staging area to check out commands before you are thrust into the world. ' \
                   'When you are ready to explore enter: "move valley".',
      items: ['Flower']
    },
    'Valley' => {
      neighbours: ['Lobby', 'Forest'],
      description: 'You are in a lush valley with a few "boar"s wandering around. ' \
                   'On the edge of the valley you notice a dark "forest".',
      items: ['Sword', 'Shield'],
      enemies: ['Boar']
    },
    'Forest' => {
      neighbours: ['Valley', 'Manor'],
      description: 'You are in a dark forest, "spider"-webs span between the trees that slow your advance. ' \
                   'Behind you is a delightful "valley" and further down the trail you can barely make out a "manor".'
    },
    'Manor' => {
      neighbours: ['Forest'],
      description: 'The Manor is locked but the grounds provide a quaint little graveyard for you to explore. '\
                   'This appears to be a dead-end with the only option going back into the "forest".'
    }
  }

  ITEMS = {
    'Flower' => {
      type: :misc
    },
    'Sword' => {
      type: :weapon,
      bonus: 0,
      damage: '1d4'
    },
    'Shield' => {
      type: :shield,
      bonus: 2,
      damage: ''
    }
  }

  ENEMIES = {
    'Boar' => {
      type: :beast,
      xp: 2,
      hit_points: 8,
      armor_class: 11,
      accuracy: -1,
      damage: '1d2'
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
      when 'score'
        score(character)
      when 'inventory'
        inventory(character)
      when 'wield'
        wield(character, message)
      when 'wear'
        wear(character, message)
      when 'pickup'
        pickup(character, message)
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
      items = ROOMS[character.current_room][:items]
      description = ROOMS[character.current_room][:description]
      description += " Looking around you also see some items laying around: #{ items }." unless items.blank?

      Event.create(
        character: character,
        room: character.current_room,
        info: description,
        personal: true
      )
    end

    def score(character)
      attrs = JSON.parse(character.score)
      value = "Level #{ attrs["lvl"] } | XP #{ attrs["xp"] } | HP #{ attrs["hp"] } | STR #{ attrs["str"] } | DEX #{ attrs["dex"] } | " \
              "Weapon (#{ attrs["weapon"] }) | Worn (#{ [attrs["armor"], attrs["shield"]].compact.join(", ") }) | " \
              "Available Skill Points #{ attrs["skill_points"] }"
      Event.create(
        character: character,
        room: character.current_room,
        info: value,
        personal: true
      )
    end

    def inventory(character)
      attrs = JSON.parse(character.inventory_data)
      Event.create(
        character: character,
        room: character.current_room,
        info: attrs.keys.size > 0 ? attrs.keys.join(", ") : "You are not carrying anything.",
        personal: true
      )
    end

    def pickup(character, possible_items)
      items_available = ROOMS[character.current_room][:items]
      successfully_picked_up = []
      already_holding = []
      missing_items = []
      inventory = JSON.parse(character.inventory_data)

      possible_items.split(" ").each do |attempted_item|
        attempted_item = attempted_item.titleize
        if items_available&.include?(attempted_item)
          if inventory.keys.include?(attempted_item)
            already_holding.push(attempted_item)
          else
            successfully_picked_up.push(attempted_item)
            inventory[attempted_item] = ITEMS[attempted_item]
          end
        else
          missing_items.push(attempted_item)
        end
      end

      msg = ""
      msg += "You successfully recovered: #{ successfully_picked_up.join(", ") }. " unless successfully_picked_up.empty?
      msg += "You were already carrying: #{ already_holding.join(", ") }. " unless already_holding.empty?
      msg += "You could not find: #{ missing_items.join(", ") }. " unless missing_items.empty?

      character.update(inventory_data: inventory.to_json)
      Event.create(
        character: character,
        room: character.current_room,
        info: msg,
        personal: true
      )
    end

    def wield(character, item)
      item = item.titleize
      inventory = JSON.parse(character.inventory_data)
      score = JSON.parse(character.score)

      if inventory.keys.include?(item)
        if ITEMS[item][:type] == :weapon
          score[:weapon] = item
          character.update(
            score: score.to_json,
          )
          Event.create(
            character: character,
            room: character.current_room,
            info: "Successfully equipped '#{ item }'.",
            personal: true
          )
        else
          Event.create(
            character: character,
            room: character.current_room,
            info: "A '#{ item }' is not a valid weapon.",
            personal: true
          )
        end
      else
        Event.create(
          character: character,
          room: character.current_room,
          info: "You were not carrying a '#{ item }'.",
          personal: true
        )
      end
    end

    def wear(character, item)
      item = item.titleize
      inventory = JSON.parse(character.inventory_data)
      score = JSON.parse(character.score)

      if inventory.keys.include?(item)
        if [:shield, :armor].include?(ITEMS[item][:type])
          score[ITEMS[item][:type]] = item
          character.update(
            score: score.to_json,
          )
          Event.create(
            character: character,
            room: character.current_room,
            info: "Successfully equipped '#{ item }'.",
            personal: true
          )
        else
          Event.create(
            character: character,
            room: character.current_room,
            info: "A '#{ item }' is not a valid piece of armor.",
            personal: true
          )
        end
      else
        Event.create(
          character: character,
          room: character.current_room,
          info: "You were not carrying a '#{ item }'.",
          personal: true
        )
      end
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
