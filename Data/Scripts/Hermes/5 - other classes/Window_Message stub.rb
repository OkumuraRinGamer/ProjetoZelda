=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes other classes (Window_Message stub)"
	This script accounts for the integration of Hermes into RGSS.
	It also resolves the \p-pseudotag.
=end
# Hermes completely kills the old Window_Message and generates a new one from
# scratch. Basically, Hermes' Window_Message can be seen as a "window manager"
# for message windows, which themselves are instances of the Hermes class.
Window_Message = Class.new

class Window_Message < Object
	def initialize
		@messages = {}
		@sync_id = nil
	end

	# SDK doesn't like that we're recreating Window_Message from scratch...
	if defined? SDK
		def disable_update?() return $scene.is_a?(Scene_Map) end
	end

	# Add unused methods in case some script calls them
	def method_missing(sym, *args)
		@messages[@sync_id].send(sym, *args) if @sync_id
	end
	def reset_window() @messages[@sync_id].reset_position if @sync_id end
	def terminate_message
		@messages[@sync_id].terminate if @sync_id
	end
	def refresh() end

	# Spawn a new message
	POPUP_REGEX = /
		\\p(?:o(?:p(?:up?)?)?)?        # Tag or abbreviation
		(?:\[
			(screen|this|hero|-1|\d+)?   # First argument
			(,async)?                    # Second argument
		\])?
	/ix
	def spawn(message_text)
		if message_text.is_a? String
			# Find any occurence of the \p tag
			if message_text.sub!(POPUP_REGEX, "")
				char = case $1
					when "screen" then -1
					when "this", nil then $game_system.map_interpreter.event_id
					when "hero" then 0
					else $1.to_i
					end
				async = ($2 != nil)
			else
				char, async = -2, false
			end
			# Empty messages are always asyncronous
			async = true if message_text.empty?
			# Load Input Number or Choice settings
			options =
			if $game_temp.num_input_variable_id > 0
				Hermes::Options::Input_Number.new($game_temp.num_input_variable_id,
					$game_temp.num_input_digits_max)
			elsif $game_temp.choice_max > 0
				Hermes::Options::Show_Choice.new(0, $game_temp.choice_max,
					$game_temp.choice_cancel_type, $game_temp.choice_proc)
			end
			# Choices and input numbers can't be asyncronous
			async = false if options
			proc = $game_temp.message_proc
		else
			async = false
			message_text, char, options, proc = *message_text
		end
		# Clear variables related to text, choices, and number input
		$game_temp.message_proc = nil
		$game_temp.choice_start = 99
		$game_temp.choice_max = 0
		$game_temp.choice_cancel_type = 0
		$game_temp.choice_proc = nil
		$game_temp.num_input_start = 99
		$game_temp.num_input_variable_id = 0
		$game_temp.num_input_digits_max = 0
		# When another non-asynchronous message is already showing
		if not async and @sync_id
			# Add back to queue, together with already parsed options
			$game_temp.message_text = [message_text, char, options, proc]
			# Abort
			return
		end
		if message_text.empty? and not options
			# Terminate asyncronous message if no text was submitted. This enables
			# the developer to manually close asynchronous messages.
			@messages[char].terminate if @messages.include?(char)
			proc.call if proc
		else
			# Set init_op to opacity of current message (canceling it) or else, 0
			if msg = @messages[char] and not msg.disposed?
				init_opacity = msg.contents_opacity
				msg.dispose
			else
				init_opacity = 0
			end
			@messages[char] = Hermes.new(char, message_text, (async ? nil : proc),
				options, init_opacity)
			if async
				# Proceed with event
				proc.call
			else
				# Memorize this message
				@sync_id = char
			end
		end
	end
	
	def reset_positions
		# To be called before Teleports
		@messages.each_value do |msg|
			msg.reset_position if msg and not msg.disposed?
		end
	end

	def update
		# Non-asynchronous message has ended and close is requested
		if @sync_id and not @messages[@sync_id].active
			@sync_id = nil
		end
		# Insert new messages while queue not empty
		while $game_temp.message_text and
					(not @sync_id or $game_temp.message_text.is_a? String)
			spawn($game_temp.message_text)
			# Remove message from queue
			$game_temp.message_text = nil
		end
		# Update asynchronous messages
		@messages.each do |char, msg|
			if msg.disposed?
				@sync_id = nil if @sync_id == char
				@messages.delete(char)
			else
				msg.update
			end
		end
	end

	def dispose
		@messages.each do |char, message|
			message.dispose unless message.disposed?
			@messages.delete(char)
		end
	end
end