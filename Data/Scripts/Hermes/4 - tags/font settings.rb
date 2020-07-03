=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes tags (font settings)"
	This script defines the following tags that can be used to control the
	message font:
	\Bold            - Switch boldness on or off (with no argument: toggle)
	\Italic          - Switch italics on or off (with no argument: toggle)
	\Font            - Change the font type (with no argument: restore default)
	\Color           - Change the font color (with no argument: restore default)
	\Opacity         - Change the font opacity (with no argument: restore default)
	\Size            - Change the font size (with no argument: restore default)
	Prepending either tag with an underscore will change the settings for the name
	box if one is present.
=end
# Tags to change the message box font
class Hermes
	name_tag(
		(live_tag "Bold", /on|off/ do |m|
			self.contents.font.bold = m[0] ? m[0] == "on" : !self.contents.font.bold
			0
		end)
	)
	name_tag(
		(live_tag "Italic", /on|off/ do |m|
			self.contents.font.italic = m[0] ? m[0] == "on" : !self.contents.font.italic
			0
		end)
	)
	name_tag(
		(live_tag "TypeFace", /.+/, :font_name do |m, sym|
			self.contents.font.name = (m[0] or Hermes.send(sym))
			0
		end), :name_font_name
	)
	name_tag(
		(live_tag "Color", /\d|#{Color::HEX_REGEX}/i, :font_color do |m, sym|
			self.contents.font.color =
			if m[0]
				if m[0].length == 1
					text_color(m[0].to_i)
				else
					Color.new(m[0])
				end
			else
				Hermes.send(sym).dup
			end
			0
		end), :name_font_color
	)
	name_tag(
		(live_tag "Opacity", /\d{1,3}/, :font_color do |m, sym|
			self.contents.font.color.alpha =
			if m[0]
				m[0].to_i
			else
				Hermes.send(sym).alpha
			end
			0
		end), :name_font_color
	)
	name_tag(
		(live_tag "Height", /\d+/, :font_size, :line_height do |m, sym1, sym2|
			size = m[0] ? m[0].to_i : Hermes.send(sym1)
			self.contents.font.size = [[size, 6].max, Hermes.send(sym1)].min
			0
		end), :name_font_size, 40
	)
	if defined? TextEffect
		name_tag(
			(live_tag "Shadow", /(\d+)?,?(\d|#{Color::HEX_REGEX})?/, :font_shadow do |m, sym|
				case m[0]
				when nil then @shadow = Hermes.send(sym).dup; ""
				when "," then false
				else
					@shadow.active = true
					@shadow.size = m[1].to_i if m[1]
					if m[2]
						@shadow.color =
						if m[2].length == 1
							text_color(m[0].to_i)
						else
							Color.new(m[2])
						end
					end
				end
				0
			end), :name_font_shadow
		)
		name_tag(
			(live_tag "Outline", /(\d+)?,?(#{Color::HEX_REGEX})?/, :font_outline do |m, sym|
				case m[0]
				when nil then @outline = Hermes.send(sym).dup; ""
				when "," then false
				else
					@outline.active = true
					@outline.size = m[1].to_i if m[1]
					if m[2]
						@outline.color =
						if m[2].length == 1
							text_color(m[0].to_i)
						else
							Color.new(m[2])
						end
					end
				end
				0
			end), :name_font_outline
		)
		name_tag(
			(live_tag "Texture", /.*/, :font_texture do |m, sym|
				@texture = m[0] ? m[0] : Hermes.send(sym)
				0
			end), :name_font_texture
		)
	end
end