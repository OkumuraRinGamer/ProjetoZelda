=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes instance methods (window maintenance)"
	Defines some "maintenance" instance methods for Hermes.
	In particular, overrides some of RGSS' default properties.
=end
class Hermes
	def contents_opacity=(o)
		super
		# Also set opacities of sub-windows
		@input_number_window.contents_opacity = o if @input_number_window
		o
	end
	
	#--------------------------------------------------------------------------

	def opacity=(o)
		super
		# Also set opacities of sub-windows
		@input_number_window.contents_opacity = o if @input_number_window
		o
	end

	#--------------------------------------------------------------------------

	def update_cursor_rect
		# Update rect used for cursor display
		if @index >= 0
			self.cursor_rect.set(@padding_left + @choice_indent,
				(@options.start + @index) * Hermes.line_height + @align_offset,
				@cursor_width, Hermes.line_height)
		else
			self.cursor_rect.empty
		end
	end

	#--------------------------------------------------------------------------

	def align_indent
		text_width = @line_widths[@cur_line] ? @line_widths[@cur_line] : 0
		# Calculate size of space for drawing text
		textarea_width =
		if not @options.is_a?(Options::Show_Choice) or @cur_line < @options.start
			self.contents.width - @padding_left - @padding_right
		else
			# Writing the choices
			@cursor_width
		end
		indent = 4 + (@align * (textarea_width - text_width - 8)) / 2
		if @options.is_a?(Options::Show_Choice) and @cur_line >= @options.start
			indent += @choice_indent
		end
		return indent
	end

	#--------------------------------------------------------------------------

	def reset_position
		# Reset position of the message window
		if @popchar >= 0 and @character

			
			# Calculate new position
			x = @character.screen_x - Hermes.event_x - self.width / 2
			y = @character.screen_y - Hermes.event_y - self.height
			# Restrict to screen unless asynchronous
			if @proc
				x = [[x, 4].max, 636 - self.width].min
				y = [[y, 4].max, 476 - self.height].min
				# Adjust position if we have a name window
				if @name_window and not Hermes.name_swap
					name_offset = @name_window.height - Hermes.name_overlap
					if Hermes.name_pos <= 1
						y = name_offset + 4 if y < name_offset + 4
					elsif y > 476 - self.height - name_offset
						y = 476 - self.height - name_offset
					end
					name_offset = @name_window.width + Hermes.name_offset - self.width
					if (1..2) === Hermes.name_pos
						x = name_offset + 4 if x < name_offset + 4
					elsif x > 636 - self.width - name_offset
						x = 636 - self.width - name_offset
					end
				end
			end

		elsif @popchar == -1
			# Display across the whole screen
			x = y = 0
		else
			# Normal display
			h = Hermes.line_max * Hermes.line_height + 32 # unshrunken height
			y = $game_temp.in_battle ? 16 :
				Hermes.margin + ($game_system.message_position *
					(480 - 2 * Hermes.margin - h)
				) / 2 # Replaced a longer case statement, see 0.3 and above
			x = 320 - (self.width / 2)
			# Change placement of shrunken window according to @align_offset
			if Hermes.shrink
				y += @align_offset
				@align_offset = 0
			end
		end
		# Set new position
		self.x, self.y = x, y
		# Update Input Number Window position
		if @options.is_a?(Options::Input_Number)
			textarea_width = self.contents.width - @padding_left - @padding_right
			x = (@align * (textarea_width - @input_number_window.width + 32)) / 2
			@input_number_window.x = self.x + x
			@input_number_window.y = self.y + @align_offset +
				@line_widths.length * Hermes.line_height
		end
	end

	#--------------------------------------------------------------------------

	def terminate
		self.active = false
		self.pause = false
		self.index = -1
		
		# Set status to closing
		@status = :closing
		
		# Continue with event execution
		@proc.call if @proc
	end

	#--------------------------------------------------------------------------

	def dispose
		$game_temp.message_window_showing = false if @proc

		# Kill message
		self.terminate unless @status == :closing
		self.contents.dispose

		# Kill input number window
		@input_number_window.dispose if @input_number_window
		super
	end
end