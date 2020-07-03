=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes instance methods (initialization)"
	The initialization routine invoked when a message is created.
	This method relies heavily on the message parser and the maintenance component
	of Hermes and won't do much on its own.
=end
class Hermes
	def initialize(char, text, proc = nil, options = nil, init_opacity = 0)
		#-----------------------------------------------------
		# Initialize instance variables and window attributes
		#-----------------------------------------------------

		super(0, 0, 10, 10)
		self.contents = Bitmap.new(1, 1)
		self.visible = false
		self.z =
		# Make active unless it is an asyncronous message
		if self.active = (@proc = proc) != nil
			$game_temp.message_window_showing = true
			9998
		else
			9995
		end
		self.index = -1
		# Initialize variables
		self.contents.font = Hermes.font
		skin_file = Hermes.skin
		skin_file = $game_system.windowskin_name
		if FileTest.exist?("Graphics/Pictures/" + skin_file)
			custom_skin = RPG::Cache.picture(skin_file)
		else
			custom_skin = nil
			self.windowskin = RPG::Cache.windowskin(skin_file)
		end
		skin_file = nil
		@sound = Hermes.sound
		@prevent_skipping = Hermes.prevent_skipping
		@write_speed = Hermes.speed
		@align, @valign = Hermes.align, Hermes.valign
		@outline, @shadow = Hermes.font_outline.dup, Hermes.font_shadow.dup
		@texture = Hermes.font_texture
		@x = @y = @cursor_width = @choice_indent = @padding_left = @padding_right =0
		@write_wait = 0
		@popchar = char
		@character = 
		if not $game_temp.in_battle
			if @popchar == 0
				$game_player
			elsif @popchar > 0
				if $game_map.events.has_key? @popchar
					$game_map.events[@popchar]
				else
					Hermes.show_debug_warning "Invalid event ID #{@popchar}."
					@popchar = -2
					nil
				end
			end
		elsif @popchar > -1
			@popchar<4 ? $game_party.actors[@popchar]: $game_troop.enemies[@popchar-4]
		end
		@align_offset = 0
		@cur_line = @scroll_break = 0
		@text_buffer = ""

		#--------------------------------
		# Get and parse the message text
		#--------------------------------

		# Get text
		@now_text = text

		# Before parsing, number the [] brackets in the message text, escaping the
		# "real" { characters
		@now_text.gsub!("{", "\\{")
		level = 0
		r = ""
		@now_text.gsub!(/(\[|\])/) do
			level -= 1 if $1 == "]"
			r = "#{$1}{#{level}}"
			level += 1 if $1 == "["
			r
		end
		r = level = nil
		
		# Parse all tags, perform word wrap and save output
		@status = :width_trial
		@now_text = parse_tags(@now_text)
		# This also sets @commands and @line_widths
		@status = :typing
		line_count = @line_widths.size
		
		#-------------------------------------------------
		# Initialize Show choice and Input number options
		#-------------------------------------------------

		# If display options where specified
		case @options = options
		when Options::Input_Number
			# Initiate Input Number Window
			@input_number_window = Window_InputNumber.new(@options.digits_max)
			@input_number_window.number = $game_variables[@options.variable_id]
			@input_number_window.contents_opacity = 0
			@input_number_window.visible = false
			line_count += 1
		when Options::Show_Choice
			# Set choice start and calculate cursor width
			visible_line_count =
			if @popchar < 0 and Hermes.line_max < line_count
				Hermes.line_max
			else
				line_count
			end
			@options.start = visible_line_count - (@item_max=@options.max)
			# Set choice width plus padding
			@cursor_width = @line_widths[@options.start..-1].max + 8
			# Don't show the cursor in the beginning
			self.index = -1
		end
		
		#---------------------------------------------------------------------------
		# Initialize the window's size and induced default positions of sub-windows
		#---------------------------------------------------------------------------

		# Set width and height of window
		if @popchar >= 0
			# Get maximal line width
			w = @line_widths.max
			if @input_number_window and @input_number_window.width > w
				# Adjust size when input number used
				w = @input_number_window.width
			end
			# Minimum width
			if w < 1
				w = 33
			else
				w += 40 + @padding_left + @padding_right
			end
			# Calculate window height
			h = line_count * Hermes.line_height
			# Minimum height
			if h < 1
				h = 33
			else
				h += 32
			end
		else
			# Apply vertical align if OSD or normal message with less than max lines
			line_max = (@popchar == -1) ? 480 / Hermes.line_height : Hermes.line_max
			if @popchar == -1 or (line_count < line_max)
				th = Hermes.line_height * (line_max - line_count)
				@align_offset = (@valign * th) / 2
			end
			if @popchar == -1
				w, h = 640, 480
			else
				w = Hermes.width
				box_line_count =
				if Hermes.shrink and line_count < Hermes.line_max 
					line_count
				else
					Hermes.line_max
				end
				h = box_line_count * Hermes.line_height + 32
			end
		end
		self.width, self.height = w, h

		# Calculate choice indent
		if @options.is_a?(Options::Show_Choice)
			textarea_width = w - 32 - @padding_left - @padding_right
			@choice_indent = (@align * (textarea_width - @cursor_width)) / 2
		end

		# Create room to draw
		self.contents = Bitmap.new(w - 32, h - 32)
		self.contents.font = Hermes.font
		@outline, @shadow = Hermes.font_outline.dup, Hermes.font_shadow.dup
		@texture = Hermes.font_texture
		if @options.is_a?(Options::Input_Number)
			@input_number_window.contents.font = self.contents.font
		end

		#----------------------------------------
		# Set initial positions of movable parts
		#----------------------------------------

		reset_position
		# Sets self.x, self.y[, @name_window.x, @name_window.y][, @face_sprite.x,
		# @face_sprite.y[, @face_sprite.align][, @name_window.indent]]
		# [, @input_number_window.x, @input_number_window.y][, @gold_window.x,
		# @gold_window.y]
		
		#-------------------------
		# Complete initialization
		#-------------------------

		# Set opacities
		if @popchar == -1 or custom_skin
			self.opacity = 0
			self.back_opacity = 0
		elsif $game_system.message_frame == 0
			self.opacity = 255
			self.back_opacity = Hermes.opacity
		else
			self.opacity = 0
			self.back_opacity = Hermes.opacity
		end
		self.contents_opacity = init_opacity

		# Draw custom window skin
		if custom_skin and $game_system.message_frame != 0
			self.contents.stretch_blt(self.contents.rect, custom_skin,
																custom_skin.rect, Hermes.opacity)
		end

		# First x offset
		@x = @padding_left + align_indent
		
		# And finally, show
		Graphics.frame_reset
		self.visible = true
	end
end