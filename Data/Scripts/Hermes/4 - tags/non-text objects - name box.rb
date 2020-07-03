=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes tags (name box)"
	This will display a smaller box next to message box that contain any string.
	Usually, this is used for the name of the current speaker.
	\NameBox         - Display name box. If a number is supplied, gets the name of
	                   the actor with this ID (with no argument: party leader)
=end
class Hermes
	tag "NameBox", /(.+)/ do |m|
		if @name_window
			return false
		else
			id = (m[1] or $game_party.actors[0].id.to_s)
			if id[/\A\d+\z/] and $game_actors[id.to_i]
				name_text = $game_actors[id.to_i].name
			else
				name_text = id
			end
			@name_window = Window_Name.new(name_text, self.z + 1)
			""
		end
	end

	# Normally we'd have to add the settings here;
	# this is done in Hermes class setup for convenience

	# Create a font out of the settings
	def self.name_font
		font = Font.new(name_font_name, name_font_size)
		font.color = name_font_color.dup
		font.bold, font.italic = name_font_bold, name_font_italic
		font
	end
end

# Main class for displaying the name window
class Window_Name < Window_Base
	attr_reader :indent, :pos
	if defined? TextEffect
		attr_accessor :shadow, :outline, :texture
	end

	# Class for the Name Window
	def initialize(name, z)
		@indent = -1
		super(0, 0, 33, 33)
		self.windowskin = RPG::Cache.windowskin(Hermes.name_skin)
		self.back_opacity = Hermes.name_opacity
		self.contents = Bitmap.new(1, 1)
		self.contents.font = Hermes.name_font
		self.z = z
		@name = name
		# Load defaults
		@pos = Hermes.name_pos
		@font = Hermes.name_font
		if defined? TextEffect
			@shadow, @outline, @texture = Hermes.name_font_shadow.dup,
				Hermes.name_font_outline.dup, Hermes.name_font_texture
		end
	end
	
	#-------------------------------------------------------------------------
	
	def draw
		size = self.contents.text_size(@name)
		w = 8 + size.width + Hermes.name_padding * 2
		self.width = w if w > 33
		h = 8 + size.height
		self.height = h if h > 33
		@text = Sprite.new
		@text.bitmap = Bitmap.new(size.width, size.height)
		@text.bitmap.font = self.contents.font
		@text.src_rect = @text.bitmap.rect
		@text.z = z + 1
		@text.opacity = 0
		if defined? TextEffect
			@text.bitmap.draw_text(
				@text.bitmap.rect, @name, 0, @shadow, @outline, @texture
			)
		else
			@text.bitmap.draw_text(@text.bitmap.rect, @name)
		end
		@name = nil
		self.contents.dispose
	end
	
	#--------------------------------------------------------------------------

	def apply_pos(parent, pos)
		@pos = pos
		return parent.x +
				if pos == 1 or pos == 2 # right
					parent.width - self.width - Hermes.name_offset
				else                    # left
					Hermes.name_offset
				end,
			parent.y +
				if pos < 2              # top
					Hermes.name_overlap - self.height
				else                    # bottom
					parent.height - Hermes.name_overlap
				end
	end
	
	#--------------------------------------------------------------------------

	def reset_position(parent, constrain_to_screen)
		draw if @name
		pos = @pos
		x, y = *apply_pos(parent, pos)
		if constrain_to_screen
			# Swap if exiting the screen
			if (pos == 1 or pos == 2) and Hermes.name_swap and x < 0
				pos = (pos-1) * 3
			elsif Hermes.name_swap and x + self.width > 640
				pos = (pos-1).abs
			end
			if pos < 2 and Hermes.name_swap and y < 0
				pos = 3 - pos
			elsif Hermes.name_swap and y + self.height > 480
				pos = (pos - 3).abs
			end
			x, y = *apply_pos(parent, pos) unless pos == @pos
		end
		self.x, self.y = x, y
	end

	#--------------------------------------------------------------------------

	unless defined? ALIASED
		ALIASED = true
		alias :real_x= :x=
		protected :real_x=
	end
	def x=(x)
		super(@indent + x)
		@text.x = @indent + x + 4 + Hermes.name_padding if @text
	end

	#--------------------------------------------------------------------------

	def y=(y)
		super(y)
		@text.y = y + 4 if @text
	end
	
	#--------------------------------------------------------------------------

	def opacity=(o)
		super(o)
		@text.opacity = o
	end

	#--------------------------------------------------------------------------

	def indent=(indent)
		self.real_x = self.x + indent - @indent
		@text.x += indent - @indent
		@indent = indent
	end

	#--------------------------------------------------------------------------

	def dispose
		@text.dispose
		super
	end

	#--------------------------------------------------------------------------

	def contents_opacity() @text.opacity end
	def contents_opacity=(opac) @text.opacity = opac end
end

=begin block
	Script "Hermes instance methods (window maintenance)"
	File "Hermes/2 - instance methods/window maintenance.rb"
	Insert_Before "11"
	Expect "		o"
=end
@name_window.contents_opacity = o if @name_window

=begin block
	Script "Hermes instance methods (window maintenance)"
	File "Hermes/2 - instance methods/window maintenance.rb"
	Insert_Before "20"
	Expect "		o"
=end
@name_window.opacity = o if @name_window

=begin block
	Script "Hermes instance methods (window maintenance)"
	File "Hermes/2 - instance methods/window maintenance.rb"
	Insert_After "104"
	Expect "		self.x, self.y = x, y"
=end
# Update Name Window position
@name_window.reset_position(self, @proc != nil) if @name_window

=begin block
	Script "Hermes instance methods (window maintenance)"
	File "Hermes/2 - instance methods/window maintenance.rb"
	Insert_Before "140"
	Expect "		super"
=end
@name_window.dispose if @name_window