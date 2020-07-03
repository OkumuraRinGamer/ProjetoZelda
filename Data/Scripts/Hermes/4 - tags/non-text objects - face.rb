=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes tags (face graphic)"
	Tag that can display a graphic in the left or right of the message box.
	Syntax: (spaces for illustration; {} = optional, | = alternative)
		\ (f|Face) [ { (actor_id|filename) } {, (number|alias) } {, (parameters) } ]
	where actor_id is the id of an actor in the database (party leader will be
	used if left out), filename the name of an image in the Pictures folder,
	number the id of the face to use from a file (if left out, the complete
	image will be used), alias an alias for a number (see face config section),
	and parameters a string containing one or more of the following arguments:
		a     - to animate the face
		c     - to use "cycling" animation type
		s     - to use "seesaw" animation type
		digit - to control the animation speed (1-9, 9=slowest)
		p     - to pause the animation when the message is paused
		d     - to disable such pauses
		l     - to display the face to the left of the text
		r     - to display it on the right
		n     - to display it in the same orientation it has in the file
		m     - to mirror it.
=end
class Hermes
	face_aliases = FACE_ALIASES.empty? ? "" : (FACE_ALIASES.keys.join("|") + "|")
	# Show face tag
	tag "Face", /([^,]+)?  # Filename of face graphic or actor ID
	                  (?:,(#{face_aliases}\d+))?
	                              # Number of face in faceset or alias (happy,...)
	                  (?:,([a     # Animate face
	                        c     # "Cycle" animation type
	                        s     # "Seesaw" animation type
	                        [1-9] # Set animation speed (frame wait)
	                        p     # Pause animation on message pause
	                        d     # Don't pause animation
	                        l     # Show face on the left
	                        r     # Show face on the right
	                        n     # Show face normally (not flipped)
	                        m     # Show face flipped horizontally
	                       ]+))? 
	                 /x do |m|
		if @face_sprite
			return false
		else
			# Default to the first party member
			face_file = (m[1] or $game_party.actors[0].id.to_s)
			# Append "face_" to the filename if number was specified
			face_file = "face_" + face_file if face_file[/\A\d+\z/]
			# Read as string or (natural) number, default to 0
			face_id = (m[2] and m[2][/\A\d+\z/]) ? m[2].to_i : (m[2] or 0)
			@face_sprite = Sprite_Face.new(face_file, self.z + 1, face_id, (m[3]or""))
			if @face_sprite.position == 0
				@padding_left = 16 + @face_sprite.face_width
			else
				@padding_right = 16 + @face_sprite.face_width
			end
			""
		end
	end
end

# Main class for displaying the face graphics
class Sprite_Face < Sprite
	attr_reader :position

	# Faceset graphic, X / Y, Face ID, whether pinned on top instead of bottom
	def initialize(graphic, z, id = 0, mode_string = "")
		# Initialize sprite
		super()

		# Load graphic
		self.bitmap = RPG::Cache.picture(graphic)
		
		# If single face graphic loaded
		if id == 0
			# Show complete bitmap
			self.src_rect = self.bitmap.rect
		# If face set loaded
		else
			# Special / invalid face IDs
			unless id.is_a? Integer
				id = (Hermes::FACE_ALIASES[id] or 1).to_i
			end
			# Set source rect
			src_y, src_x = *(id - 1).divmod(4)
			face_width = self.bitmap.width / 4
			src_x *= face_width
			src_y *= Hermes::Face::HEIGHT
			self.src_rect.set(src_x, src_y, face_width, Hermes::Face::HEIGHT)
		end

		# Load default settings
		@anim_speed = Hermes::Face::Animation::SPEED
		@anim_mode = Hermes::Face::Animation::MODE
		@anim_pause = Hermes::Face::Animation::PAUSE
		@position = (Hermes::Face::POSITION == :right) ? 1 : 0
		self.mirror = Hermes::Face::MIRROR

		# Parse mode string
		mode_string.scan /./ do |s|
			case s
			when "a" then @anim_frame = 0
			when "c" then @anim_mode = :cycle
			when "s" then @anim_mode = :seesaw
			when "p" then @anim_pause = true
			when "d" then @anim_pause = false
			when "l" then @position = 0
			when "r" then @position = 1
			when "n" then self.mirror = false
			when "m" then self.mirror = true
			when /\d/ then @anim_speed = s.to_i
			end
		end
		if @anim_frame
			# Limit height to Hermes::Face::HEIGHT
			self.src_rect.height = Hermes::Face::HEIGHT
			@anim_increment = 1
			@anim_frame_max = Hermes::Face::Animation::SPEED *
			                  self.bitmap.height / Hermes::Face::HEIGHT
		end
		# Set z order
		self.z = z
		# Make transparent
		self.opacity = 0
	end
	
	#--------------------------------------------------------------------------
	
	def reset_position(parent, constrain_to_screen)
		self.x = parent.x + 16
		self.x += parent.width - face_width - 32 if @position == 1
		# If window is tall enough
		if @align == 1
			self.y = parent.y + parent.height/2
			return nil
		else
			# Window is not tall enough
			if not constrain_to_screen or
				 parent.y + parent.height - 32 >= self.face_height
				# Face can be shown aligned to bottom because either there's enough
				# space or we don't care if it exits the screen
				self.align = 2
				# Message is not displayed on top and not in full screen
				self.y = parent.y + parent.height - 16
				return @position
			else
				# Face must be aligned on top of the message
				self.align = 0
				# Message is displayed on top or in full screen
				self.y = parent.y + 16
				return 3 - @position
			end
		end
	end
	
	#--------------------------------------------------------------------------
	
	def update(pause)
		if @anim_frame
			if @anim_pause and pause
				# Don't animate in pause mode
				if @anim_frame != 0
					@anim_frame = 0
					self.src_rect.y = 0
				end
			else
				if @anim_mode == :seesaw
					if @anim_frame == @anim_frame_max - 1
						@anim_increment = -1
					elsif @anim_frame == 0
						@anim_increment = 1
					end
				end
				@anim_frame = (@anim_frame + @anim_increment)  % @anim_frame_max
				self.src_rect.y = face_height  * (@anim_frame / @anim_speed)
			end
		end
	end
	
	#--------------------------------------------------------------------------
	
	def face_width
		# Return the selected face's width
		return self.src_rect.width
	end

	#--------------------------------------------------------------------------

	def face_height
		# Return the selected face's height
		return self.src_rect.height
	end

	#--------------------------------------------------------------------------

	attr_reader :align
	def align=(align)
		# Set pin position
		align = 1 unless (0..2) === align
		self.oy = (align * self.src_rect.height) / 2
		@align = align
	end
	
	# Hide some methods
	protected :ox=, :oy=
end

=begin block
	Script "Hermes instance methods (window maintenance)"
	File "Hermes/2 - instance methods/window maintenance.rb"
	Insert_Before "11"
	Expect "		o"
=end
@face_sprite.opacity = o if @face_sprite

=begin block
	Script "Hermes instance methods (window maintenance)"
	File "Hermes/2 - instance methods/window maintenance.rb"
	Insert_After "104"
	Expect "		self.x, self.y = x, y"
=end
# Update Face Sprite position
if @face_sprite
	# Set position of the face sprite if window is tall enough
	if self.height - 32 >= @face_sprite.face_height
		@face_sprite.align = 1
	end
	condpos = @face_sprite.reset_position(self, @proc != nil)
	# Update Name Window pos
	if @name_window and condpos
		# If face and name are to be shown in the same corner
		pos = @name_window.pos
		if pos == condpos
			# Indent name window
			@name_window.indent = 
				(1 - 2 * @face_sprite.position) * (@face_sprite.face_width + 16)
		else # (Face and name are in different corners)
			name_xpos = (pos % 3 == 0) ? 0 : 1
			# If Y positions differ
			if (pos <= 1 and condpos > 1) or (pos > 1 and condpos <= 1)
				# No collision possible, place it normally
				@name_window.indent = 0
			else
				# Sadly, in this case, face and name window can still collide if the
				# name window is long enough. It is really really hard to decide
				# what to do at this point. I'm having the name window slide out of
				# the way; this is but one solution and might push the name window
				# out of screen (what some of the above might do anyway, so wth)
				free_space = (self.width - @face_sprite.face_width -
											2*Hermes.name_offset -16)
				if @name_window.width > free_space
					@name_window.indent =
						(2 * name_xpos - 1) * (@name_window.width - free_space)
				end
			end
		end
	end
end

=begin block
	Script "Hermes instance methods (window maintenance)"
	File "Hermes/2 - instance methods/window maintenance.rb"
	Insert_Before "140"
	Expect "		super"
=end
@face_sprite.dispose if @face_sprite

=begin block
	Script "Hermes instance methods (frame update)"
	File "Hermes/2 - instance methods/frame update.rb"
	Insert_Before "54"
	Expect "		case @status"
=end
# Animate face sprite if applicable
@face_sprite.update(self.pause) if @face_sprite