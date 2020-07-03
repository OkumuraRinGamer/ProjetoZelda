=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes tags (other non-text objects)"
	These are tags for miscellaneous (wut?) non-text objects.
	\Display          - Show face and name box at once (see face command)
	\Gold             - Show / hide a box that shows the money owned (no argument)
	\Sound            - Change the typing sound (with no argument: turn off)
=end
class Hermes
	if (defined? Name) and (defined? Face)
		tag "Display", find_tag("Face").params do |m|
			tag_face(m) + tag_namebox(m)
		end
	end
	live_tag "Gold" do
		if width_trial?
			0
		else
			if not @gold_window
				if @popchar != -1
					@gold_window = Window_Gold.new
					@gold_window.back_opacity = Hermes.opacity
					@gold_window.reset_position self
				end
			else
				@gold_window.dispose
				@gold_window = nil
			end
		end
	end
	live_tag "Sound", /.+/ do |m| @sound = m[0]; 0 end
end

class Window_Gold
	def reset_position(parent)
		if $game_temp.in_battle or parent.x + (parent.width / 2) <= 320
			self.x = 560 - self.width
		else
			self.x = 80
		end
		if $game_temp.in_battle
			self.y = 192
		else
			self.y = (parent.y + (parent.height / 2) <= 240) ? 384 : 32
		end
	end
end

=begin block
	Script "Hermes instance methods (window maintenance)"
	File "Hermes/2 - instance methods/window maintenance.rb"
	Insert_Before "11"
	Expect "		o"
=end
@gold_window.contents_opacity = o if @gold_window

=begin block
	Script "Hermes instance methods (window maintenance)"
	File "Hermes/2 - instance methods/window maintenance.rb"
	Insert_Before "20"
	Expect "		o"
=end
@gold_window.opacity = o if @gold_window

=begin block
	Script "Hermes instance methods (window maintenance)"
	File "Hermes/2 - instance methods/window maintenance.rb"
	Insert_Before "113"
	Expect "	end"
=end
# Update Gold Window position
@gold_window.reset_position self if @gold_window

=begin block
	Script "Hermes instance methods (window maintenance)"
	File "Hermes/2 - instance methods/window maintenance.rb"
	Insert_Before "140"
	Expect "		super"
=end
@gold_window.dispose if @gold_window