=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes other classes (other, patches)"
	The *other* other classes. Extends Game_Temp, adds a method to String and
	patches various RGSS classes.
=end
# Hermes needs $game_temp.message_text to be able to hold multiple values.
# This is done below.
class Game_Temp
  # Okay this is the basis of what makes multiple messages possible. Instead of
  # overwriting the old one, message_text= simply adds the new message to a
  # queue, of which message_text always reads the latest one.
  def message_text=(text)
    case text
    when String then @message_texts << text
    when Array then @message_texts.unshift(text)
    else @message_texts.pop
    end
    text
  end

  def message_text
    @message_texts[-1]
  end
end

# Get length of a string in characters instead of in bytes
class String
	def u_length
		return gsub(/./m, " ").length
	end
end

=begin script
	Name "Hermes Hex Colors"
	Insert_Before "Hermes tags (font settings)"
	Alias "Color#initialize => hermes_old_init"
=end
# Support HTML style hexcode for colors
class Color
	HEX_REGEX = /\#([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})?/i
	def initialize *args
		if args.length == 1 and args[0].is_a? String and args[0][/\A#{HEX_REGEX}\z/]
			# Valid hex color, create it
			hermes_old_init($1.hex, $2.hex, $3.hex, ($4 ? $4.hex : 255))
		else
			hermes_old_init(*args)
		end
	end
end

=begin block
	Script "Game_Temp"
	Insert_Before "106"
	Expect "  end"
=end
@message_texts = []

=begin block
	Script "Scene_Map"
	Insert_After "263"
	Expect "    end"
=end
@message_window.reset_positions

=begin block
	Script "Scene_Save"
	Insert_Before "83"
	Expect "  end"
=end
Marshal.dump(Hermes.to_hash, file)

=begin block
	Script "Scene_Load"
	Insert_After "82"
	Expect "    $game_player        = Marshal.load(file)"
=end
# If saved game doesn't contain Hermes save, load defaults
Hermes.load_hash(file.eof? ? Hash.new : Marshal.load(file))

=begin block
	Script "Main"
	Insert_After "7"
	Expect "begin"
=end
Hermes.load_hash Hash.new