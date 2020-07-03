=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes instance methods (message parser)"
	THE core component of Hermes. Parser the messages to recognize commands and
	performs the word wrap if selected.
=end
class Hermes
	def width_trial?
		@status == :width_trial
	end

	#--------------------------------------------------------------------------

	def wrap_words words
		result = ""
		max_width = (@popchar < 0 ? Hermes.width : 624)
		max_width -= 32 + @padding_left + @padding_right
		@line_widths = [0]
		words.each do |word|
			# Add a break if a word is not the first in line, not empty, but too long
			if WRAP_MODE == :auto and word.string[0,1] == " " and word.width > 0 and
				 word.space_width + word.width > max_width - @line_widths[-1]
				word.string[0] = "\n" 
			end
			result << word.string
			# Update line width
			if word.string[0,1] == "\n" # 10 == "\n"
				@line_widths << word.width
			else
				@line_widths[-1] += word.space_width + word.width
			end
		end
		return result
	end

	#--------------------------------------------------------------------------
	
	# Parses all the tags in a message
	NEXT_CHAR = /./m
	NEXT_TAGNAME_CHAR = /\A[^\[\\]/m
	ARGUMENTS = /\A\[(\{\d+\})(.*?)\]\1/
	COUNTER = /\d+\}/
	def parse_tags(string, internal = false)
		# This translates all tags specified in @@tags and extracts line widths
		if internal
			result = ""
		else
			@commands = []
			words = [Word.new("", 0, 0)]
		end
		replace = ""
		m = nil
		pos = 0
		tag_name, tag = nil
		tag_found = arg_found = ""
		empty_tags_only = (string[0,1] != "\n")
		while char = string.slice!(NEXT_CHAR)
			case char
			when "\\"
				if string[0,1] == "\\" or char == "{"
					# Escaping
					char = string.slice!(NEXT_CHAR)
				else
					# Found a tag, check which one it is
					tag_found = ""
					# First, check all aliases
					@@aliases.each do |search, insert|
						if string.sub!(search, insert)
							break
						end
					end
					node = @@tags
					while char = string.slice!(NEXT_TAGNAME_CHAR)
						tag_found << char
						char.downcase!
						unless node[char]
							break
						else
							node = node[char]
							break if node.length == 1
						end
					end
					tag =
					if node.length == 1
						# Only one option left, kill remaining characters if any
						begin
							char, node = node.to_a[0]
						end until char == :tag or not string.slice!(/\A#{char}/i)
						# Follow the path without deleting further to get to the tag
						while node.is_a? Hash
							node = node.values[0]
						end
						# And we have our tag!
						node
					end
					# If we found a valid tag
					if tag
						# Find submitted params
						arg_found =
						if string.slice!(ARGUMENTS)
							$2
						end
						# If [] brackets are supplied (always replace if no argument found)
						replace =
						if arg_found
							if tag.params
								# Parse tags in the argument
								arg_found = parse_tags(arg_found, true)
								# Match the result against the params RegExp
								(m = arg_found.match(tag.params).to_a).length != 0
							else
								# Arguments supplied for a tag not requiring any arguments
								# Don't execute
								false
							end
						else
							m = []
							true
						end
						if replace
							# Save the line and pos so that tags can call add_command
							args = [m, *tag.other_params]
							replace = send(tag.method, *args)
							if tag.live and not internal
								# The return value should be a number
								if replace > 0
									words[-1].width += replace
									empty_tags_only = false
								end
								replace = ""
								# Will be executed again later
								unless @commands[pos]
									@commands[pos] = []
								end
								@commands[pos] << Command.new(tag.method, args)
							end
							# Don't print the char... whatever it is now
							char = nil
						else
							# If tag method returns false, warn if we're in debug mode
							Hermes.show_debug_warning(
								"Invalid syntax for #{tag.name} tag.\n" +
								"Tag ignored. Please fix your project."
							)
							char = "\\"
						end
						# Don't replace tag if used incorrectly
						replace = replace ? replace.to_s : 
											tag_found + (arg_found ? "[#{arg_found}]" : "")
						string.insert(0, replace)
					else
						# Warn about missing tag
						Hermes.show_debug_warning(
							"Unknown or ambiguous tag '#{tag_found}'.\n"+
							"Tag ignored. Please fix your project."
						)
						char = "\\"
						string.insert(0, tag_found)
					end
				end
			when " "
				# Spaces only concern us in top level, otherwise just copy them
				unless internal
					# Handle character insertion differently
					pos += 1
					empty_tags_only = false
					words << Word.new(char, self.contents.text_size(char).width, 0)
					char = nil
				end
			when "\n"
				if empty_tags_only # Ignore lines with only tags
					char = nil
					# Insert a new word
					words << Word.new("", 0, 0) unless internal
				else
					# Set empty tags only flag if next line isn't entirely empty
					empty_tags_only = (string[0,1] != "\n")
					# Insert a new word starting with newline
					unless internal
						pos += 1
						words << Word.new(char, 0, 0)
						char = nil
					end
				end
			when "$"
				# Set correct replacement from replacement table
				char = string.slice!(/./m)
				if REPLACEMENTS.include?(char)
					char = REPLACEMENTS[char]
				else
					char = "$#{char}"
				end
			when "{"
				# Delete bracket depth counter
				string.slice!(COUNTER)
				char = nil
			end
			if char
				pos += 1
				# Line is definitely not entirely composed of empty tags
				empty_tags_only = false
				if internal
					result << char
				else
					words[-1].string << char
					words[-1].width += self.contents.text_size(char).width
				end
			end
		end

		# Perform word wrap
		result = wrap_words(words) unless internal
		# (This will also define @line_widths)

		# If the last line is only composed of empty tags
		if empty_tags_only
			# Remove last character if it is a newline
			if result.chomp! and not internal
				# Also remove last entry from @line_widths
				@line_widths.pop
			end
		end

		return result
	end
end