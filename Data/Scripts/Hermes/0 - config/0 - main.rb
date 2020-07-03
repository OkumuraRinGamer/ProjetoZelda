=begin script                    â–  Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes configuration (main)"
	Here is where you can configure the core aspects of Hermes.
=end
class Hermes < Window_Selectable
	#===========================================================================
	# â—? Main configuration section
	#===========================================================================
	module GlobalText                # Global Font / Style Configuration
		NAME    = Font.default_name      # Font name (case sensitive)
		SIZE    = Font.default_size      # Text size in pixel
		COLOR   = Font.default_color     # Text color (Color.new(red, green, blue))
		BOLD    = Font.default_bold      # Text boldness (true/false)
		ITALIC  = Font.default_italic    # Text italicness   -"-
	end

	# Set the button to skip the dialog
	#  B = Escape, 0 (On The NumPad), X
	#  C = Enter, Space Bar and C
	#  A = Shift, Z
	SKIP_TEXT_CODE = Input::C

	# Use backwards compatible tag names. In compatibility mode, choices will be
	# appended to the previous message if its number of lines plus the number of
	# choices does not exceed 4 ("auto-append choices"). Possible values:
	# - "RGSS": tags only compatible to the original RMXP message script
	# - "AMS+": tags backwards compatible to AMS and AMS+
	# - "Hermes0.2": tags backwards compatible to Hermes 0.1 to 0.2c
	# - "Hermes0.3": tags backwards compatible to Hermes 0.3 to 0.3d
	# - true: no compatibility for tags, only auto-append choices
	# - nil: only compatible to Hermes >= 0.3
	TAG_VERSION = nil
	# Setting compatibility mode might reduce speed.
	
	# Enable warnings on errors in debug mode. These are only shown when the game
	# is run from RPG Maker, they won't appear if it is started normally.
	# It is recommended to leave this at true while building the game and during
	# beta testing, afterwards it can be turned off (but it doesn't matter).
	DEBUG_WARNINGS = false
	
	# RPG maker doesn't save the line breaks in the Show Text commands properly.
	# It only saves the lines as they appear in the editor. Therefore, line breaks
	# must be inserted by the message script. Hermes knows 3 different ways to do
	# this:
	# :default
	#    This will simply add a line break after every original line from the
	#    Show Text dialog. This is the way RGSS does it by default.
	# :auto
	#    First, lines which contain nothing but empty tags are removed. Then,
	#    Hermes will try to recreate the *intended* line breaks: a line break is
	#    only added if the current line does not end with a space. Lastly, the
	#    complete message is automatically word-wrapped to fill the message box.
	# :manual
	#    No linebreaks are inserted, but an additional tag \l (or \Linebreak) will
	#    be defined to add a manual line break.
	WRAP_MODE = :auto

	# All the settings below this point are only default values and can be changed
	# during the game using $msg. See documentation / demo for details.
	module Message                 # Configuration for message box
		module Text                    # Configuration for the text it contains
			NAME    = "M" # Font's name (case sensitive)
			SIZE    = :default             # Text size in pt
			COLOR   = :default             # Text color (Color.new(r, g, b))
			BOLD    = :default             # Text boldness (true/false)
			ITALIC  = :default             # Text italicness   -"-
			ALIGN   = 0                    # Horizontal text align (0, 1 or 2)
			VALIGN  = 1                    # Vertical text align (0, 1, or 2)
			SOUND   = :off                 # Sound to play on each letter
			SPEED   = 1                    # Speed for text display (0=â??)
			PREVENT_SKIPPING = false       # Prevent the user from skipping text
		end
		module Box                     # Configuration for the box itself
			WIDTH   = 480                  # Width (yeah, really?)
			LINE_MAX= 4                    # Number of lines displayed at once
			SHRINK  = true                 # Shrink if less lines used (true/false)
			LINE_HEIGHT = 32               # Height of each line in pixels
			MARGIN  = 18                   # Spacing from border
			EVENT_X = 0                    # X offset when shown over an event
			EVENT_Y = 48                   # Y offset when shown over an event
			OPACITY = 255                  # Opacity (255 = fully opaque)
			SKIN    = :default             # Windowskin
		end
	end

	# Character replacements ($A - $z)
	REPLACEMENTS = {
		"$" => "$", # Dollar sign
		"a" => "â?º", "b" => "â?»", "c" => "â?¹", # Happy, black happy (1), and sad faces
		"d" => "â??", "e" => "â?„", # Cloud, snow flake (one / two water drops in RM2k)
		"f" => "â™¤", "g" => "â™¡", "h" => "â™¢", "i" => "â™§", # As below, but not filled
		"j" => "â™ ", "k" => "â™¥", "l" => "â™¦", "m" => "â™£", # Card game symbols
		# Skull, Christian cross, Sun, Moon (2), Star/Bullet
		"n" => "â? ", "o" => "â??", "p" => "â?€", "q" => "â?¾", "r" => "â€¢",
		"s" => "â‡§", "t" => "â‡¨", "u" => "â‡©", "v" => "â‡¦", # North, East, South, West
		"w" => "â¬€", "x" => "â¬‚", "y" => "â¬ƒ", "z" => "â¬?", # NE, SE, SW and NW arrows
		"A" => "â?®", "B" => "â?¢", "C" => "â?¡", # Peace, radioactive, Star of David (3)
		"D" => "â?‰", "E" => "â?½", "F" => "â?¿", "G" => "â™€", # Sun, Moon, Mercury, Venus
		"H" => "â™?", "I" => "â™‚", "J" => "â™ƒ", "K" => "â™„", # Earth,Mars,Jupiter,Saturn
		"L" => "â™…", "M" => "â™†", "N" => "â™‡", # Uranus, Neptune, Pluto
		"O" => "â™?", "P" => "â™‰", "Q" => "â™?", # Aries, Taurus, Gemini
		"R" => "â™‹", "S" => "â™?", "T" => "â™?", # Cancer, Leo, Virgo
		"U" => "â™?", "V" => "â™?", "W" => "â™?", # Libra, Scorpio, Sagittarius
		"X" => "â™‘", "Y" => "â™’", "Z" => "â™“"  # Capricorn, Aquarius, Pisces
		# (1): This is a neutral face in RM2k.
		# (2): In RM2k, this is a filled half moon. Here it's a mirrored $E.
		# (3): Was Sword, Shield, Star of David in RM2k.
	}.freeze
end
