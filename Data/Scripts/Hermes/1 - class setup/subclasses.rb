=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes class setup (subclasses)"
	This defines a few subclasses used by Hermes. Most of them are just Structs,
	but then there's also validationn rules and settings. See Hermes/Romkan for
	an example of how to use them (or, of you're adventurous, look at the default
	tag sources).
=end
class Hermes
	#===========================================================================
	# ● Various structs used by Hermes
	#===========================================================================
	Tag = Struct.new("Hermes_Tag", :name, :params, :other_params, :live, :method)
	Command = Struct.new("Hermes_Command", :method, :params)
	Char = Struct.new("Hermes_Char", :c, :commands)
	Word = Struct.new("Hermes_Word", :string, :space_width, :width)

	module Options
		Input_Number = Struct.new('Hermes_Input_Number', :variable_id, :digits_max)
		Show_Choice=Struct.new('Hermes_Show_Choice',:start,:max,:cancel_type,:proc)
	end

	#===========================================================================
	# ● Classes needed for settings
	#===========================================================================
	# A validation rule
	class Rule
		class << self
			def [] condition, action = nil
				new condition, action
			end
		end
		def initialize condition, action = nil
			@condition, @action = condition, action
		end
		def comply? value
			case value
			when *@condition then true
			end
		end
		def apply value
			case @action
			when nil then value
			when Proc then @action.call value
			else @action
			end
		end
	end
	# A validation ruleset
	class RuleSet
		VALIDATION_WARNING = "Incorrect value %s, corrected to %s."
		class << self
			def [] fallback, *rules
				new fallback, *rules
			end
		end
		def initialize fallback, *rules
			@fallback, @rules = fallback, rules
		end
		def validate value
			for rule in @rules
				return rule.apply value if rule.comply? value
			end
			Hermes.show_debug_warning(
				format VALIDATION_WARNING, value.inspect, @fallback.inspect
			)
			return @fallback
		end
	end
	# When a new Setting is created, it will sort itself into these two hashes
	SETTINGS_BY_GETTER = {}
	SETTINGS_BY_SETTER = {}
	# A setting
	class Setting
		attr_reader :getter, :setter
		def initialize getter, const_section=Hermes, const_name = getter.to_s.upcase
			@getter, @const_section, @const_name =
				getter.to_sym, const_section, const_name.to_sym
			@setter = "#{getter}=".to_sym
			@late_values = {}
			Hermes::SETTINGS_BY_GETTER[@getter] = self
			Hermes::SETTINGS_BY_SETTER[@setter] = self
		end
		def get_default_value
			@const_section.const_get @const_name
		end
		def set_old_value_getter *args, &old_value_getter
			if block_given?
				@old_value_getter = old_value_getter
				@args = args
			elsif not args.empty?
				@args = *args
			end
		end
		def get_old_value hgs
			if @old_value_getter
				@old_value_getter.call hgs, *@args
			elsif @args
				@args
			else
				hgs.instance_variable_get "@#{getter}"
			end
		end
		def add_late_value value, *args, &block
			@late_values[value.to_s] = [block, args]
		end
		def resolve_late_values value
			key = value.to_s
			if @late_values.has_key? key
				proc, args = @late_values[key]
				proc.call *args
			else
				value
			end
		end
		def set_validation_ruleset ruleset
			@validation_ruleset = ruleset
		end
		def validate value
			if @validation_ruleset and not @late_values.has_key? value.to_s
				@validation_ruleset.validate value
			else
				value
			end
		end
	end
end