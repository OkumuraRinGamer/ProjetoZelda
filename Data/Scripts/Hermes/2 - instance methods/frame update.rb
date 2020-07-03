=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes instance methods (frame update)"
	Defines the core method called at frame update and som auxilliary methods.
=end
class Hermes
	# Determine wether to show the text at once
	def skip_text?
		# - We're NOT in pause mode and:
		#   - Allowed to skip and pressing enter or
		#   - In debug mode and control held and enter pressed
		skip_key_trigger = Input.trigger?(Hermes::SKIP_TEXT_CODE)
		@status != :pause and (
			(self.active and not @prevent_skipping and skip_key_trigger) or
			($DEBUG and Input.press?(Input::CTRL) and skip_key_trigger)
		)
	end
	
	#--------------------------------------------------------------------------

	def current_drawing_y
		@y * Hermes.line_height + @align_offset
	end
	
	#--------------------------------------------------------------------------

	def flush_buffer
		unless @text_buffer.empty?
			w = self.contents.text_size(@text_buffer).width
			self.contents.draw_text(
				@x, current_drawing_y, w * 2, Hermes.line_height,
				@text_buffer, 0, @shadow, @outline, @texture
			)
			@x += w
			@text_buffer = ""
		end
	end
	
	#--------------------------------------------------------------------------

	def update
		super()

		# Move Message Box with event
		if not $game_temp.in_battle and @character and
			(@character.moving? or $game_player.moving? or $game_map.scrolling?)
			reset_position
		end
		
		# Perform Fade-in
		unless @status == :closing
			self.contents_opacity += 24 if self.contents_opacity < 255
		end
		
		case @status
		when :typing
			# Decrease frames to wait
			@write_wait -= 1 if @write_wait > 0
			# Wait until next frame unless we've waited long enough or are skipping
			return unless @write_wait == 0 or skip_text?

			while @now_text != "" or not @commands.empty?

				# Execute the commands one by one
				if @commands[0]
					# A command can change everything, better flush the buffer
					flush_buffer
					while command = @commands[0].shift
						# Execute it
						send(command.method, *command.params)
						# Exit if we have to wait or status has changed
						return unless @status == :typing and (@write_wait == 0 or skip_text?)
					end
				end
				
				# Delete first command list (because it is empty! (or should be^^))
				@commands.shift

				if c = @now_text.slice!(/./m)
					if c == "\n"
						# Draw anything we might have collected
						flush_buffer
						# New line
						@cur_line += 1
						@x = @padding_left + align_indent
						if @popchar > -2 or @cur_line < Hermes.line_max
							@y += 1
						else
							# Duplicate to blt it later
							@oldcontents = self.contents.dup
							@scroll_break = (@scroll_break + 1) % Hermes.line_max
							if @scroll_break == 1
								@status = :pause
								break
							end
						end
					else
						# Move old three lines to top
						if @oldcontents
							self.contents.clear
							self.contents.blt(0, -Hermes.line_height,
								@oldcontents, @oldcontents.rect)
							@oldcontents.dispose
							@oldcontents = nil
						end
						# We have a letter! Add it to the buffer
						@text_buffer << c
						# Don't play a sound during instant display
						if @sound and @write_speed > 0
							Audio.se_play("Audio/SE/" + @sound)
						end
					end
				end

				# Continue with next letter if skipping
				if skip_text? or @write_speed == 0
					next
				else
					# Draw whatever's left
					flush_buffer
					# Stretch time to wait by global speed factor and add own wait time
					@write_wait = (@write_wait + 1) * @write_speed
					return
				end
			end
			
			# Draw the rest, if any
			flush_buffer

			# Switch to done status when text is fully drawn
			if @now_text == "" and @commands.empty? and
				(@write_wait == 0 or skip_text?)
				if @options.is_a?(Options::Show_Choice)
					# Also, show the choice cursor
					@index = 0
				elsif @options.is_a?(Options::Input_Number)
					# ...or the input number window
					@input_number_window.contents.font = self.contents.font
					@input_number_window.refresh
					@input_number_window.visible = true
				end
				# Show continue cursor if applicable
				self.pause = (@options == nil and self.active)
				# Set status to done if fully faded in
				@status = :done
			end
		when :pause
			# Switch to pause mode if not yet in it
			if self.active and not self.pause
				self.pause = true
				@write_wait = 0
			end

			if Input.trigger?(Input::C)
				# Enter key pressed: resume dialog
				@status = :typing
				self.pause = false
			end
		when :done
			# Pass control to input number window
			if @options.is_a?(Options::Input_Number)
				# Update input number window
				@input_number_window.update
				if Input.trigger?(Input::C)
					# Enter key pressed
					$game_system.se_play($data_system.decision_se)
					$game_variables[@options.variable_id] = @input_number_window.number
					$game_map.need_refresh = true
					self.terminate
				end
			elsif @options.is_a?(Options::Show_Choice)
				# Choice is active
				if Input.trigger?(Input::B) and
					# Escape key pressed
					if @options.cancel_type > 0
						$game_system.se_play($data_system.cancel_se)
						@options.proc.call(@options.cancel_type - 1)
						self.terminate
					end
				end
				if Input.trigger?(Input::C)
					# Enter key pressed
					$game_system.se_play($data_system.decision_se)
					@options.proc.call(self.index)
					self.terminate
				end
			elsif self.active
				# Enter key pressed: close dialog
				self.terminate if Input.trigger?(Input::C)
			end
		when :closing
			# Start fading out
			self.opacity -= 48
			self.contents_opacity -= 48
			self.dispose if self.contents_opacity == 0
		end
	end
end