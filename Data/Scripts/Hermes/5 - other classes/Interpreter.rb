=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes other classes (Interpreter)"
	This modifies RMXP's Interpreter to allow Hermes to do different kind of new
	things. Also, resolves the \*-pseudotag.
=end
class Interpreter
	#--------------------------------------------------------------------------
	# * Show Text
	#--------------------------------------------------------------------------
	MERGE_REGEX = /\\\*/
	def command_101
		# Wait one frame if a message is already waiting to be displayed
		if $game_temp.message_proc
			return false
		end
		# Set message text on first line
		if not @message_text
			@message_text = ""
		elsif Hermes::WRAP_MODE == :default or
				(Hermes::WRAP_MODE == :auto and @message_text[-1,1] != " ")
			@message_text << "\n"
		end
		@message_text << (line = @list[@index].parameters[0])
		line_count = 1 if Hermes::TAG_VERSION
		# Loop
		loop do
			# If next event command text is on the second line or after
			if @list[@index+1].code == 401
				# Prepend a line break if we are in a correct mode
				if Hermes::WRAP_MODE == :default or
					(Hermes::WRAP_MODE == :auto and line[-1,1] != " ")
					@message_text << "\n"
				end
				# Add the second line or after to message_text
				@message_text << (line = @list[@index+1].parameters[0])
				line_count += 1 if Hermes::TAG_VERSION
			else
				# If in compatibility mode and
				# - Next event command is input number and number input window fits or
				# - Next event command is show choices and choices fit on screen
				if Hermes::TAG_VERSION and Hermes::TAG_VERSION != "Hermes0.3" and (
						((n = @list[@index+1]).code == 103 and line_count < 4)
						(n.code == 102 and n.parameters[0].size <= 4 - line_count) 
					)
					# Continue (message is shown in next step)
					return true
				end
				break
			end
			# Advance index
			@index += 1
		end
		# Continue only if message text contains \* tag
		continue = @message_text.sub!(MERGE_REGEX, "")
		unless continue
			# Set message end waiting flag and callback
			@message_waiting = true
			$game_temp.message_proc = Proc.new { @message_waiting = false }
			# Show message
			$game_temp.message_text = @message_text
			@message_text = nil
		end
		return continue
	end
	#--------------------------------------------------------------------------
	# * Show Choices
	#--------------------------------------------------------------------------
	def command_102
		# Wait one frame if a message is already waiting to be displayed
		if $game_temp.message_proc
			return false
		end
		# Set message end waiting flag and callback
		@message_waiting = true
		$game_temp.message_proc = Proc.new { @message_waiting = false }
		# Set choice item count to choice_max
		$game_temp.choice_max = @parameters[0].size
		# Set choice to message_text
		if @message_text
			@message_text << "\n"
		else
			@message_text = ""
		end
		@message_text << @parameters[0][0]
		for text in @parameters[0][1..-1]
			@message_text += "\n" + text
		end
		# Set cancel processing
		$game_temp.choice_cancel_type = @parameters[1]
		# Set callback
		current_indent = @list[@index].indent
		$game_temp.choice_proc = Proc.new { |n| @branch[current_indent] = n }
		# Show message and choices
		$game_temp.message_text = @message_text
		@message_text = nil
		# Continue
		return true
	end
	#--------------------------------------------------------------------------
	# * Input Number
	#--------------------------------------------------------------------------
	def command_103
		# Wait one frame if a message is already waiting to be displayed
		if $game_temp.message_proc
			return false
		end
		# Set message end waiting flag and callback
		@message_waiting = true
		$game_temp.message_proc = Proc.new { @message_waiting = false }
		# Number input setup
		$game_temp.num_input_variable_id = @parameters[0]
		$game_temp.num_input_digits_max = @parameters[1]
		# Show message and input number
		$game_temp.message_text = (@message_text or "")
		@message_text = nil
		# Continue
		return true
	end

	def event_id
		if @list and $game_map.events[@event_id].trigger <= 2
			@event_id
		else
			0
		end
	end
end