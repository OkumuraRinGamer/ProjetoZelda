=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes tags (compatibility)"
	This scripts tries to aid you in upgrading from older message systems to
	Hermes. At the moment, compatibility modes for RGSS, AMS / AMS+, Hermes 0.2
	and Hermes 0.3 are included. They are more based on instinct than on actual
	testing, so if you find an issue with either, do not hesitate to contact me.
	One warning: Message parsing in compatibility mode might be considerably
	slower (one exception is TAG_VERSION = true; see config/main.rb for details).
=end
class Hermes
	case TAG_VERSION
	when "RGSS" then
		add_aliases /n(?!a)/i => "ac"
	when "AMS+" then
		add_aliases /[Cc]id/ => "#", /[Cc]hara/ => "d", /n(?!a)/i => "ac",
				/m\[/i => "v[e", /[Ii]con/ => "sy", /z/i => "_c", /c(?!l)/i => "co",
				/s(?![yoh])/i => "sp", /a(?![lc])/i => "so", /t(?!e)/i => "ty",
				">" => "s[0]", "<" => "s", "~" => "^", /o(?!u)/i => "op"
	when "Hermes0.2"
		add_aliases /data/i => "d", /cid/i => "#", /a(?!l)/i => "ac",
				/cost|co(?!l)/i => "pr", /z/i => "_c", /ta(?:lign)?/i => "align",
				/tb(?:old)?/i => "b", /ti(?:talic)?/i => "i", /tf(?:ont)?/i => "ty",
				/tc(?:olor)?/i => "co", /ts(?:peed)?/i => "sp", /to(?:pacity)?/i => "op",
				/th(?:eight)?/i => "h", /icon/i => "symbol", /s(?![yoh])/i => "sp"
	when "Hermes0.3"
		add_aliases "Chara" => "d", "MemberID" => "#", /a(?![Ll])/ => "ac",
				"q" => "pr", "j" => "cl", /z|NameColor/ => "_c", "x" => "al",
				/t(?![Ee])|Font/ => "ty", /c(?![Ll])/ => "co", /s(?![YyOoHh])/ => "sp",
				/o(?![Uu])/ => "op", "Size" => "h", "PreventSkip" => "%",
				/y|Icon/ => "sy", "r" => "so", "Wait1" => ".", "Wait4" => "|",
				"Pause" => "!", "Close" => "^"
	end
end