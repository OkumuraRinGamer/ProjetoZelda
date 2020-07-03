=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes tags (special strings)"
	With these tags you can insert special strings into the message, like values
	from the database, game variables or also icons.
	\#              - Get actor ID of party member (w/ no argument: party leader)
	\Actor          - Display the name of an actor (w/ no argument: party leader)
	\Class          - Display actor class (with no argument: party leader)
	\Map            - Display map name (with no argument: name of current map)
	\Variable       - Display enemy, item, weapon, armor or skill name or the
	                  value of a game variable (argument required)
	\Event          - Display name of an event (with no argument: calling event)
	\Price          - Display the price of an item (argument required)
	\/              - Insert a linebreak (only registered if WRAP_MODE == :manual)
	                  (no argument)
	\Symbol         - Display an icon (argument required)
=end
class Hermes
	# Load the map names
	MAP_NAMES = Hash.new
	load_data("Data/MapInfos.rxdata").each do |key, info|
		MAP_NAMES[key] = info.name
	end
	MAP_NAMES.freeze

	tag "#", /[0-3]/ do |m|
		$game_party.actors[m[0] ? m[0].to_i : 0].id
	end
	tag "Actor", /\d+/ do |m|
		id = m[0] ? m[0].to_i : $game_party.actors[0].id
		$game_actors[id] ? $game_actors[id].name : false
	end
	tag "Class", /\d+/ do |m|
		id = m[0] ? m[0].to_i : $game_party.actors[0].id
		if $data_classes[$data_actors[id].class_id]
			$data_classes[$data_actors[id].class_id].name
		else
			false
		end
	end
	tag "Map", /\d+/ do |m|
		id = (m[0] ? m[0].to_i : $game_map.map_id)
		if MAP_NAMES.include?(id)
			MAP_NAMES[id]
		else
			Hermes.show_debug_warning "Invalid map ID #{id}."
			""
		end
	end
	tag "Variable", /([eiwas])?,?(\d+)/i do |m|
		item =
		if m[0]
			index = m[2].to_i
			arg = m[1]
			case arg
				when "e" then $data_enemies[index]
				when "i" then $data_items[index]
				when "w" then $data_weapons[index]
				when "a" then $data_armors[index]
				when "s" then $data_skills[index]
				else $game_variables[index]
			end
		end
		if not item
			false
		elsif arg == "e" or not respond_to? :tag_symbol
			item.name
		elsif arg
			"\\symbol[{0}#{item.icon_name}]{0} #{item.name}"
		else
			item
		end
	end
	tag "Event", /this|\d+/ do |m|
		if not m[0] or m[0] == "this"
			id = $game_system.map_interpreter.event_id
		else
			id = m[0].to_i
		end
		return $game_map.events[id] ? $game_map.events[id].name : false
	end
	tag "Price", /\d+/ do |m|
		id = m[0] ? m[0].to_i : -1
		$data_items[id] ? $data_items[id].price : false
	end
	if WRAP_MODE == :manual
		tag "/" do "\n" end
	end
	live_tag "Symbol", /.+/ do |m|
		if m[0]
			icon = RPG::Cache.icon(m[0])
			if @status == :width_trial
				# Calculate the width
				icon.width
			else
				if m[0]
					self.contents.blt(@x , (@y + 0.5) * Hermes.line_height +
														@align_offset - icon.height / 2, icon, icon.rect)
					Audio.se_play("Audio/SE/" + @sound) if @sound
				end
				@x += icon.width
			end
		end
	end

	case TAG_VERSION
	when "RGSS" then
		add_alias(/n/i, "a")
	when "AMS+" then
		add_aliases({/[Cc]id/ => "#", "class" => "j", "map" => "\000m", "icon" => "y"},
		            :first)
		add_aliases({/n/i => "a", /m\[/i => "v[e", "V" => "v", "price" => "q"})
		add_alias("\000m", "m")
	when "Hermes0.2" then
		add_alias(/i(?:con)?/i, "y", :first)
		add_aliases({/a(?:ctor)?/i => "a", /cl(?:ass)?/i => "j", /v(?:ar)?/i => "v",
		             /e(?:vent)?/i => "e", /co(?:st)?/i => "q", /c(?:id)?/i => "#",
		             /m(?:ap)?/i => "m"})
	end
end

# Make the event name readable
class Game_Event
	def name
		return @event.name
	end
end

# Make the current map ID readable
class Game_Map
	attr_reader :map_id
end