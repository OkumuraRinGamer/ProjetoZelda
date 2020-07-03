=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes settings initialization"
	Defines the default set of Hermes settings, including all the default tags.
	Settings only get initialized if the corresponding tags are present, of
	course.
=end
class Hermes
	#===========================================================================
	# ● Define default set of settings
	#===========================================================================
	# Loader for old font values
	font_old_proc = Proc.new do |hgs, var, sym|
		hgs.instance_variable_get(var).instance_variable_get "@#{sym}"
	end
	# Define the late default getters for some individual settings
	font_default_proc = Proc.new { |name| Font.send("default_#{name}") }
	font_default_proc_dup = Proc.new do |name, setting|
		send setting.setter, Font.send("default_#{name}").dup
	end
	text_effect_default_proc =
	if defined? TextEffect
		Proc.new do |name, setting|
			# Ehm... this is required because the send variant like in
			# font_default_proc_dup won't work here because texture can be nil which
			# is treated as a magical value and oh my god this is too weird.
			self.module_eval(
				"@@#{setting.getter}"+' = TextEffect.send("global_#{name}")'
			)
		end
	end
	default_procs = {
		"name" => font_default_proc, "size" => font_default_proc,
		"bold" => font_default_proc, "italic" => font_default_proc,
		"color" => font_default_proc_dup, "texture" => text_effect_default_proc,
		"outline" => text_effect_default_proc, "shadow" => text_effect_default_proc,
		"skin" => Proc.new { $game_system.windowskin_name }
	}
	# Define validation rules for each setting
	string_rule = Rule[String]; int_rule = Rule[Integer]
	bool_rule = Rule[[true, false]]
	color_default_validation  = RuleSet[:default, Rule[Color],
		Rule[String, Proc.new { |string| Color.new string }]
	]
	boolean_default_validation = RuleSet[:default, Rule[[true, false]]]
	align_validation = RuleSet[0, Rule[[0, 1, 2]]]
	nil_proc = Proc.new { nil }
	text_effect_validation =
	if defined? TextEffect
		RuleSet[:default, Rule[TextEffect],
		  Rule[Array, Proc.new { |array| TextEffect.new *array }]
		]
	end
	class ::Proc
		alias === call
	end
	greater_zero_rule = Rule[Proc.new do |value|
		(value.is_a?(Integer) and value > 0)
	end]
	# This includes validation rules for all default tags for convenience.
	# Don't worry, if a tag is removed, the corresponding validator will soon be
	# deleted. It's just a shortcut for those that *are* defined.
	validation_rules = {
		"name" => RuleSet[:default, string_rule, Rule[Array]],
		"size" => RuleSet[:default, greater_zero_rule],
		"color" => color_default_validation,
		"bold" => boolean_default_validation, "italic" =>boolean_default_validation,
		"align" => align_validation, "valign" => align_validation,
		"sound" => RuleSet[nil, Rule[[:off, "off"], nil_proc], string_rule],
		"speed" => RuleSet[1, Rule[0], greater_zero_rule],
		"prevent_skipping" => RuleSet[false, bool_rule],
		"texture" => RuleSet[:default, string_rule, Rule[:none, nil_proc]],
		"outline" => text_effect_validation, "shadow" => text_effect_validation,
		"width" => RuleSet[480, greater_zero_rule],
		"line_max" => RuleSet[4, greater_zero_rule],
		"shrink" => RuleSet[true, bool_rule],
		"line_height" => RuleSet[32, greater_zero_rule],
		"margin" => RuleSet[16, int_rule],
		"event_x" => RuleSet[0, int_rule], "event_y" => RuleSet[48, int_rule],
		"opacity" => RuleSet[150, Rule[0..255]],
		"skin" => RuleSet[:default, string_rule],
		"pos" => RuleSet[0, Rule[[0, 1, 2, 3]]],
		"overlap" => RuleSet[16, int_rule],
		"offset" => RuleSet[8, int_rule], "padding" => RuleSet[4, int_rule],
		"swap" => RuleSet[true, bool_rule]
	}
	# Message box settings have an empty prefix, Name box settings have name_
	sections = [[Message, ""]]
	if constants.include? "Name"
		sections << [Name, "name_",]
	end
	for section, prefix1 in sections
		for subsection_name in section.constants
			subsection = section.const_get subsection_name
			for constant_name in subsection.constants
				name = constant_name.downcase
				# Font values aren't explicitly distinguished as such in the constants,
				# but in the variables they are, so we need to add that to the prefix.
				prefix2 =
				case name
				when "name","size","color","bold","italic","outline","shadow","texture"
					"font_"
				else
					""
				end
				# The setting is automatically inserted into the lists
				setting = Setting.new prefix1+prefix2 + name, subsection, constant_name
				# Needed to load font values from older savegames (Hermes < 0.4)
				unless prefix2.empty?
					var = "@#{prefix1+prefix2[0..-2]}".to_sym
					setting.set_old_value_getter var, name.to_sym, &font_old_proc
				end
				# Define default value getters if defined
				if default_procs.has_key? name
					proc = default_procs[name]
					arguments = [name, setting]
					arguments.slice! proc.arity..1
					setting.add_late_value :default, *arguments, &proc
				end
				# Define validator if defined
				if validation_rules.has_key? name
					setting.set_validation_ruleset validation_rules[name]
				end
			end
		end
	end
	if defined? Hermes::Name
		# Allow to convert an existing live tag into a standard name box tag
		def self.name_tag tag, *other_params
			name, params, block = tag
			sym = "tag_#{name}".to_sym
			Window_Name.module_eval do
				define_method sym, block
			end
			self.tag "_#{name}", params, *other_params do |m, *other_params|
				if @name_window
					@name_window.send sym, m, *other_params
					""
				end
			end
		end # WHY DO I FEEL SO DIRTY CAN ANYONE CLEAN ME PLEASE
	else
		def self.name_tag *args
			# Placeholder
		end
	end
end

# Create the well-known shortcut
untrace_var :$msg
$msg = Hermes
#$msg.load_hash Hash.new
trace_var(:$msg) do
	Hermes.show_debug_warning(
		"I know that you are planning to reassign $msg, and I'm "+
	  "afraid that's something I cannot allow to happen.\n"+
		"(If you know what you're doing, please untrace_var :$msg first.)"
	)
	$msg = Hermes
end

# Define this for backwards compatibility only
class Hermes_Global_Settings
	def method_missing sym, *args
		Hermes.send sym, *args
	end
end