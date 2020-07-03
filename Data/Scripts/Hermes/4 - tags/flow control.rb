=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes tags (flow control)"
	These tags control other properties of text display unrelated to how the font
	will look like, such as speed, pauses, etc.
	\Align          - Change text alignment (with no argument: restore default)
	\Speed          - Change the display speed (with no argument: restore default)
	\%              - Prevent immediate display of text (with no argument: toggle)
	\.              - Wait for five frame (no argument)
	\|              - Wait for twenty frames (no argument)
	\!              - Require the player to press enter to continue (no argument)
	\^              - Close the message immediately (no argument)
=end
class Hermes
	tag "Align", /
	  (l(?:eft)?|c(?:enter)?|r(?:ight)?),
	  ?(t(?:op)?|m(?:iddle)?|b(?:ottom)?)
	/x do |m|
		if m[0]
			@align = case m[1][0,1]
				when 'l' then 0
				when 'c' then 1
				when 'r' then 2
			end
			@valign = case m[2][0,1]
				when 't' then 0
				when 'm' then 1
				when 'b' then 2
			end
		else
			@align = Hermes.align
			@valign = Hermes.valign
		end
		""
	end
	live_tag "Speed", /\d+/ do |m|
		# Don't change in width trial mode
		width_trial? ? 0 : (@write_speed = m[0] ? m[0].to_i : Hermes.speed)
	end
	live_tag "%", /on|off/ do |m|
		width_trial? ? 0 : (@prevent_skipping = m[0] ? (m[0] == "on") : !@prevent_skipping)
	end
	live_tag "." do width_trial? ? 0 : (@write_wait += 5       ) end
	live_tag "|" do width_trial? ? 0 : (@write_wait += 20      ) end
	live_tag "!" do width_trial? ? 0 : (@status      = :pause  ) end
	# Only terminate if not in the middle of skipping text
	# (thus, if a \^ tag is skipped over, the box ends up closable by the player.
	# This is intentional behavior.)
	live_tag "^" do width_trial? ? 0 : (skip_text? or terminate) end
end