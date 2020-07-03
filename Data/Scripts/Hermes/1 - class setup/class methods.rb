=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes class setup (class methods)"
	Here, mandatory class methods for the Hermes class are defined. These methods
	will be used to register tags and settings with Hermes, and to load and save
	the settings from / to savegames.
=end
class Hermes
	# Shows a warning in Debug mode (can be disabled, dee config/main.rb)
	def self.show_debug_warning warning
		if $DEBUG and DEBUG_WARNINGS
			print warning + "\n\n(This warning is only shown in debug mode.)"
		end
	end

	#===========================================================================
	# ● Methods for adding tags and compatibility aliases
	#===========================================================================
	# These methods are required for the tags to get added.
	@@tags = {}; @@aliases = []
	def self.tag(name, params = nil, *other_params, &block)
		name.downcase!
		node = @@tags
		name.scan /./m do |char|
			unless node.has_key? char
				node[char] = {}
			end
			node = node[char]
		end
		if node.has_key? :tag
			show_debug_warning("Tag #{name} already exists and will be overwritten.")
		end
		meth = "tag_#{name}".to_sym
		define_method meth, &block
		node[:tag] = Tag.new(name, /\A#{params}\z/, other_params, false, meth)
	end
	def self.live_tag(name, params = nil, *other_params, &block)
		tag(name, params, *other_params, &block).live = true
		# This is such an ugly hack that OH LOOK IT'S A TREE
		[name, params, block]
	end
	def self.find_tag name
		tag = name.downcase
		node = @@tags
		while char = tag.slice!(/./m)
			node = node[char]
			break unless node
		end
		node[:tag] if node
	end
	# Method for adding one or more aliases for compatibility mode.
	def self.add_aliases(hash)
		for key, value in hash
			@@aliases << [/\A#{key}/, value]
		end
	end
	
	#===========================================================================
	# ● Methods for reading, changing, loading and saving settings
	#===========================================================================
	# Throw me out new fonts if requested
	def self.font
		font = Font.new(font_name, font_size)
		font.color = font_color.dup
		font.bold, font.italic = font_bold, font_italic
		font
	end
	# This methods is used to access any setting that might be added
	def self.method_missing sym, *args
		property = (sym.to_s[/[^=]*/]).to_sym
		is_assignment = sym != property
		# Load appropriate setting
		if is_assignment
			setting = SETTINGS_BY_SETTER[sym]
		else
			setting = SETTINGS_BY_GETTER[sym]
			# Show a debug warning and "try to recover" if an argument is supplied
			unless args.empty?
				show_debug_warning "Wrong number of arguments (#{args.length} for 0)." +
						               "\nTrying to continue..."
			end
		end
		# Show a debug warning and cancel if the setting is undefined
		unless setting
			show_debug_warning "Invalid Hermes setting #{property}.\n" +
			                   "Trying to continue..."
			return nil
		end
		v =
		if is_assignment
			arg = args[0]
			# Load default value if arg is nil
			unless arg
				arg = setting.get_default_value
			end
			arg = setting.validate arg
			" arg"
		else
			# This would ensure that it never crashes on missing stuff...but what for?
			#send "#{sym}=", nil unless class_variables.include? "@@#{sym}"
			""
		end
		# Store or read value (damn Ruby 1.8.1 for not having class_method_set!)
		result = module_eval "@@#{sym}#{v}"
		if is_assignment
			result
		else
			# Resolve "default" values etc.
			setting.resolve_late_values result
		end
	end

	#--------------------------------------------------------------------------
	
	# Load settings from Hash
	def self.load_hash(hash)
		if hash.is_a? Hash # Load new format
			for sym, setting in SETTINGS_BY_SETTER
				send sym, hash[setting.getter]
			end
		elsif hash.is_a? Hermes_Global_Settings
			for sym, setting in SETTINGS_BY_SETTER
				send sym, setting.get_old_value(hash)
			end
		else
			show_debug_warning "Hermes save data couldn't be loaded." +
			                   "Using default values."
			for sym, setting in SETTINGS_BY_SETTER
				send sym, nil
			end
		end
	end
	
	# Dump settings to hash
	def self.to_hash
		res = {}
		for sym, setting in SETTINGS_BY_GETTER
			res[sym] = send sym
		end
		res
	end
end