#=============================================================================
# ■ Hermes - Hermes Extends RMXP's MEssage System - Version 0.4
#-----------------------------------------------------------------------------
# Hermes/Romkan extension
# This is an example extension for Hermes which allows you to add Hiragana
# to your messages.
# This script uses Ruby/Romkan, Copyright (C) 2001 Satoru Takabayashi.
# For more information on Ruby/Romkan, and what I've changed in it, see below
#=============================================================================

# We want to expand Hermes, right? So we start as follows:
class Hermes
	# To add a new tag, there are several things to do. First, you must add the
	# tag to Hermes's list of tags. This is done via the class methods
	# tag or live_tag. Use the first of those if you want your tag's method to be
	# executed while the message is being created. This is useful for settings
	# that affect the complete message, like the \a or \f tags.
	# When using the live_tag method, your method will be called twice: once while
	# it is calculating the lines' widths of the message (this is the same
	# instance where non-live tags are called), and once later, before the letter
	# following to this command is being displayed. This is useful if you want to
	# make dynamic changes, like changing the font (\t) or the size (\h) of the
	# text following this tag.
	# However, you must not change anything but the message font
	# (self.contents.font) during the first call. To determine whether your method
	# is called during text measuring or during text display (when you create a
	# live tag), check if @status equals :width_trial. If it does, Hermes window
	# is currently determining the width of the text. Remember that you may not
	# change anything but self.contents.font in this case!
	# If the tag is not a live tag, it will replaced with the return value of your
	# tag's function, except if this return value is false, in which case the tag
	# will not be removed from the message (i.e., to indicate a parsing error).
	# Instead, a debug message will be shown if this feature is activated.
	# If the tag is live, it should return an Integer during width trial to
	# determine how much space the result should take up.

	# This is the tag definition. The first argument is the tag name. Tag names
	# are case insensitive and can always be shortened as long as the shortcut
	# is still ambigious. Thus, by choosing a short tag name you're not helping
	# anybody. Instead, try to choose a tag name not conflicting with too many
	# others, so that it can be abbreviated as well as possible.
	# The tag name also serves as a unique identifier. Be aware that if you 
	# re-define an already existing tag name, your tag will replace the old one.
	# The second argument is a Regexp which pre-determines whether the supplied
	# argument is well-formed. The one below allows everything as an argument.
	tag "Kana", /.*/ do |m|
		# What this tag does is nothing but translate everything into separate live
		# tags. It's mainly a convenience so that people don't have to be careful
		# and verbose with the live tag, as it only works for correct, single
		# characters.
		return m[0].to_live_sequence
	end

	# Next, we define the live tag. I am using a Japanese tag name here, because
	# you're not supposed to call it directly. The tag is "ichi", i.e. "one".
	# Because, well, each live tag only contains one single kana.
	# If you look at the to_live_sequence method at the bottom of this file,
	# you'll recognize the parameter format used below: the first item will be the
	# main character sequence, the second the miniature.
	live_tag "一", /(.+),(.+)/ do |m|
		# First, remember the old font and apply the new one.
		font_before = self.contents.font.name
		self.contents.font.name = Hermes.kana_font_name
		# Note that the above will be (has to be!) performed in :width_trial mode as
		# well as in normal mode. Now here's the difference between the modes:
		if @status == :width_trial
			# In width trial mode, we just need to find out how much space we need,
			# that is, the width of the large character.
			result = self.contents.text_size(m[1]).width
		else
			# Outside of width trial mode, we need to actually draw things.
			# First, we draw the large one. To do that correctly, we simply add it to
			# the drawing buffer which will automatically be drawn when appropriate.
			@text_buffer << m[1]
			# Also, we need to flush the buffer to get to the correct x position.
			# Flushing will draw the complete buffer to the output.
			flush_buffer
			# Now, for the miniature
			if Hermes.kana_mini_pos != :off
				# First, we need to know the width of both characters...
				large_width = self.contents.text_size(m[1]).width
				small_width = self.contents.text_size(m[2]).width
				# ... and their heights.
				large_height = self.contents.font.size
				small_height = Hermes.kana_mini_size
				# Now, we have to determine the position to draw it at.
				# This is tricky, because there's lots of things you have to consider
				# with Hermes, like line height, font size, alignments...
				x = @x - large_width
				y_offset = (Hermes.line_height-large_height)/2 - small_height / 2 
				if Hermes.kana_mini_pos == :above # Drawn above
					y = current_drawing_y + y_offset
				else
					y = current_drawing_y + Hermes.line_height - y_offset
				end
				# And finally, draw it!
				font_size_before = self.contents.font.size
				self.contents.font.size = Hermes.kana_mini_size
				self.contents.draw_text(x, y, large_width, small_height, m[2], 1)
				self.contents.font.size = font_size_before
				# Done! Apart from the y magic, nothing really difficult happened.
			end
			result = nil
		end
		# Set the font back to whatever it was before
		self.contents.font.name = font_before
		result
	end

	# Add a compatibility tag if requested in the configuration:
	if TAG_VERSION == "Hermes0.2"
		Hermes.add_alias(/k(?:ana)?/i, "k")
	end
	# (This of course is only required if your tag already existed in the older
	# version, which is very unlikely. :P)

	# In many cases, the above tag definition would be enough to completely define
	# a tag. In the tags folder of Hermes you can see many such examples. However,
	# in this case, we also want to provide the user options to be able to
	# change the font used for kana tags both globally and during the game,
	# as well as some settings for the miniature.

	# This can be achieved with a few simple commands.
	module Kana
		# Default Japanese font
		FONT_NAME = :default
	end
	# This doesn't do anything yet but specify the default setting.
	# (If you release your tag, you will most likely want to place the above
	# snippet at the top of your code, so that users can easily change its value)

	# Now to be able to save this setting into savegames, we need to add a new
	# Setting to Hermes. This is really simple! Look:
	setting = Setting.new(:kana_font_name, Hermes::Kana, :FONT_NAME)
	# - The first argument is the Symbol for the setting name. It is used as a
	#   means to access your setting via $msg ($msg.kana_font_name in this case).
	#   (As of Hermes 0.4, $msg is merely a shortcut to Hermes)
	#   Also, it will be used as the name of the class variable storing the value,
	#   in this case, @@kana_font_name.
	# - The second argument is the module or class that contains your default
	#   setting. If it is left out, this will be Hermes.
	# - The third argument is the name of the constant, as a Symbol. If it is left
	#   out, this will be the first argument converted to upper case.
	# You can submit more arguments to the function or a block; these will be used
	# for backwards compatibility. Usually, you can leave that out and it will
	# work just fine (it does have a default compatibility loader).

	# Next, we need to tell it what to to when the user sets the font name to
	# :default. This is a "magical" value, that means, its actual meaning changes
	# in context. What it actually stands for can only be decided "late", i.e. in
	# the instance it is used. Thus, we tell Hermes that it is a late value and
	# how to read it:
	setting.add_late_value(:default) do
		# Load the default message font
		Hermes.font_name
	end

	# Finally, set the validation ruleset. A validation ensures that only correct
	# values are applied to the variable and makes a debug message pop up on 
	# attempts of invalid assignments if the developer enabled them and the game
	# is run in debug mode.
	setting.set_validation_ruleset(RuleSet[:default, Rule[String], Rule[Array]])
	# RuleSet[] creates a new ruleset, containing a fallback value and an
	# arbitrary number of rules. If the new value doesn't match any of these
	# rules, our setting will be set to the fallback value instead.
	# A rule is created via Rule[condition, action], where condition is either of
	# - an Array which the value must be a member of
	# - a class which the value must be an instance of
	# - a single object that must be identical to the value
	# - a Proc accepting a single parameter and returning true or false in
	#   depending on the correctness of the setting.
	# The action, if defined, can be:
	# - A Proc accepting a single parameter which will be called if the value does
	#   match the rule. The result of the call is saved instead of the original
	#   value,
	# - an object which will be saved instead of the value if it matches the rule,
	# - nil (which equals to leaving it out), in which case the value will be
	#   saved directly in case of a match.
	# In our example, if the user calls $msg.kana_font_tag = x, Hermes will check
	# if x is a String or an Array. If it is either, it will set @@kana_font_tag
	# to x (action = nil), otherwise it will display a warning and set
	# @@kana_font_tag to :default.
	# Exemplarily, this rule could be replaced with the following, which will
	# check if the font actually exists before assigning it:
	#   Rule[ Proc.new { |value| value.is_a?(String) and Font.exist?(value) } ]
	# Or, look at this example:
	#   Rule[Object, "PANCAKES!!"]
	# [...]
	#   $msg.kana_font_name = "Waffles!"
	#   print $msg.kana_font_name           # => PANCAKES!!
	# etc. etc. etc.

	# Okay, this was one setting. Here's the rest, a bit faster.
	module Kana
		# Determines if Kana or Romaji should be printed (:kana/:romaji)
		MAIN_SET = :kana
		# Determines position of miniature. The typeset not used as main set will
		# be used to draw the miniatures. Values: :above / :below / :off
		MINIATURE_POSITION = :above
		# Determines the font size of miniatures
		MINIATURE_SIZE = 12
	end
	# Setting for MAIN_SET
	setting = Setting.new(:kana_main_set, Hermes::Kana, :MAIN_SET)
	setting.set_validation_ruleset(RuleSet[:kana, Rule[[:kana, :romaji]]])
	# Setting for MINITAURE_POSITION
	setting = Setting.new(:kana_mini_pos, Hermes::Kana, :MINIATURE_POSITION)
	setting.set_validation_ruleset(RuleSet[:above, Rule[[:above, :below, :off]]])
	# Setting for MINIATURE_SIZE
	setting = Setting.new(:kana_mini_size, Hermes::Kana, :MINIATURE_SIZE)
	# This validation ensures the supplied argument is a positive Integer
	setting.set_validation_ruleset(RuleSet[12, Rule[
		Proc.new { |value| value.is_a?(Integer) and value > 0 }
	]])
end



#
# Ruby/Romkan - a Romaji <-> Kana conversion library for Ruby.
#
# Copyright (C) 2001 Satoru Takabayashi <satoru@namazu.org>
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the Ruby's licence.
#
# NOTE: Ruby/Romkan can work only with EUC_JP encoding. ($KCODE="e")
#
# NOTE (Hermes author): The above note isn't true, at least not for Romaji ->
#     Kana conversion. I modified the original Ruby/Romkan library by simply
#     running them through a little PHP script which converted it from EUC_JP
#     to Unicode, and it works, as far as I can tell. I'm not sure whether
#     Kana -> Romaji would also work, as I've removed it, but it should. Also,
#     I've added Romaji to Katakana conversion (UPPER CASE LETTERS will be
#     translated to Katakana, lower case ones to Hiragana).
#     I've removed all the constants and methods that aren't used in the code
#     above, which is all of them except KUNREITAB, HEBBURNTAB,
#     normalize_double_n and to_kana, and then added punctuation and space
#     conversion. For the full version (though without the latter), see
#     Takabayashi-san no webusaito at http://0xcc.net/ruby-romkan/
#

module Romkan
  VERSION = '0.4'
end

class Array
  def pairs(s=2)
    0.step(self.size-1,s){
      |x| yield self.slice(x,s)
    }
  end
end
	
class String
# This table is imported from KAKASI <http://kakasi.namazu.org/> and modified.
  KUNREITAB = "\
ぁ	xa	あ	a	ぃ	xi	い	i	ぅ	xu
う	u	う゛	vu	う゛ぁ	va	う゛ぃ	vi 	う゛ぇ	ve
う゛ぉ	vo	ぇ	xe	え	e	ぉ	xo	お	o 

か	ka	が	ga	き	ki	きゃ	kya	きゅ	kyu 
きょ	kyo	ぎ	gi	ぎゃ	gya	ぎゅ	gyu	ぎょ	gyo 
く	ku	ぐ	gu	け	ke	げ	ge	こ	ko
ご	go 

さ	sa	ざ	za	し	si	しゃ	sya	しゅ	syu 
しょ	syo	じ	zi	じゃ	zya	じゅ	zyu	じょ	zyo 
す	su	ず	zu	せ	se	ぜ	ze	そ	so
ぞ	zo 

た	ta	だ	da	ち	ti	ちゃ	tya	ちゅ	tyu 
ちょ	tyo	ぢ	di	ぢゃ	dya	ぢゅ	dyu	ぢょ	dyo 

っ	xtu 
っう゛	vvu	っう゛ぁ	vva	っう゛ぃ	vvi 
っう゛ぇ	vve	っう゛ぉ	vvo 
っか	kka	っが	gga	っき	kki	っきゃ	kkya 
っきゅ	kkyu	っきょ	kkyo	っぎ	ggi	っぎゃ	ggya 
っぎゅ	ggyu	っぎょ	ggyo	っく	kku	っぐ	ggu 
っけ	kke	っげ	gge	っこ	kko	っご	ggo	っさ	ssa 
っざ	zza	っし	ssi	っしゃ	ssya 
っしゅ	ssyu	っしょ	ssho 
っじ	zzi	っじゃ	zzya	っじゅ	zzyu	っじょ	zzyo 
っす	ssu	っず	zzu	っせ	sse	っぜ	zze	っそ	sso 
っぞ	zzo	った	tta	っだ	dda	っち	tti 
っちゃ	ttya	っちゅ	ttyu	っちょ	ttyo	っぢ	ddi 
っぢゃ	ddya	っぢゅ	ddyu	っぢょ	ddyo	っつ	ttu 
っづ	ddu	って	tte	っで	dde	っと	tto	っど	ddo 
っは	hha	っば	bba	っぱ	ppa	っひ	hhi 
っひゃ	hhya	っひゅ	hhyu	っひょ	hhyo	っび	bbi 
っびゃ	bbya	っびゅ	bbyu	っびょ	bbyo	っぴ	ppi 
っぴゃ	ppya	っぴゅ	ppyu	っぴょ	ppyo	っふ	hhu 
っふぁ	ffa	っふぃ	ffi	っふぇ	ffe	っふぉ	ffo 
っぶ	bbu	っぷ	ppu	っへ	hhe	っべ	bbe	っぺ    ppe
っほ	hho	っぼ	bbo	っぽ	ppo	っや	yya	っゆ	yyu 
っよ	yyo	っら	rra	っり	rri	っりゃ	rrya 
っりゅ	rryu	っりょ	rryo	っる	rru	っれ	rre 
っろ	rro 

つ	tu	づ	du	て	te	で	de	と	to
ど	do 

な	na	に	ni	にゃ	nya	にゅ	nyu	にょ	nyo 
ぬ	nu	ね	ne	の	no 

は	ha	ば	ba	ぱ	pa	ひ	hi	ひゃ	hya 
ひゅ	hyu	ひょ	hyo	び	bi	びゃ	bya	びゅ	byu 
びょ	byo	ぴ	pi	ぴゃ	pya	ぴゅ	pyu	ぴょ	pyo 
ふ	hu	ふぁ	fa	ふぃ	fi	ふぇ	fe	ふぉ	fo 
ぶ	bu	ぷ	pu	へ	he	べ	be	ぺ	pe
ほ	ho	ぼ	bo	ぽ	po 

ま	ma	み	mi	みゃ	mya	みゅ	myu	みょ	myo 
む	mu	め	me	も	mo 

ゃ	xya	や	ya	ゅ	xyu	ゆ	yu	ょ	xyo
よ	yo

ら	ra	り	ri	りゃ	rya	りゅ	ryu	りょ	ryo 
る	ru	れ	re	ろ	ro 

ゎ	xwa	わ	wa	ゐ	wi	ゑ	we
を	wo	ん	n 

ん     n'
でぃ   dyi
ー     -
ちぇ    tye
っちぇ	ttye
じぇ	zye

ァ	XA	ア	A	ィ	XI	イ	I	ゥ	XU
ウ	U	ウ゛	VU	ウ゛ァ	VA	ウ゛ィ	VI 	ウ゛ェ	VE
ウ゛ォ	VO	ェ	XE	エ	E	ォ	XO	オ	O 

カ	KA	ガ	GA	キ	KI	キャ	KYA	キュ	KYU 
キョ	KYO	ギ	GI	ギャ	GYA	ギュ	GYU	ギョ	GYO 
ク	KU	グ	GU	ケ	KE	ゲ	GE	コ	KO
ゴ	GO 

サ	SA	ザ	ZA	シ	SI	シャ	SYA	シュ	SYU 
ショ	SYO	ジ	ZI	ジャ	ZYA	ジュ	ZYU	ジョ	ZYO 
ス	SU	ズ	ZU	セ	SE	ゼ	ZE	ソ	SO
ゾ	ZO 

タ	TA	ダ	DA	チ	TI	チャ	TYA	チュ	TYU 
チョ	TYO	ヂ	DI	ヂャ	DYA	ヂュ	DYU	ヂョ	DYO 

ッ	XTU 
ッウ゛	VVU	ッウ゛ァ	VVA	ッウ゛ィ	VVI 
ッウ゛ェ	VVE	ッウ゛ォ	VVO 
ッカ	KKA	ッガ	GGA	ッキ	KKI	ッキャ	KKYA 
ッキュ	KKYU	ッキョ	KKYO	ッギ	GGI	ッギャ	GGYA 
ッギュ	GGYU	ッギョ	GGYO	ック	KKU	ッグ	GGU 
ッケ	KKE	ッゲ	GGE	ッコ	KKO	ッゴ	GGO	ッサ	SSA 
ッザ	ZZA	ッシ	SSI	ッシャ	SSYA 
ッシュ	SSYU	ッショ	SSHO 
ッジ	ZZI	ッジャ	ZZYA	ッジュ	ZZYU	ッジョ	ZZYO 
ッス	SSU	ッズ	ZZU	ッセ	SSE	ッゼ	ZZE	ッソ	SSO 
ッゾ	ZZO	ッタ	TTA	ッダ	DDA	ッチ	TTI 
ッチャ	TTYA	ッチュ	TTYU	ッチョ	TTYO	ッヂ	DDI 
ッヂャ	DDYA	ッヂュ	DDYU	ッヂョ	DDYO	ッツ	TTU 
ッヅ	DDU	ッテ	TTE	ッデ	DDE	ット	TTO	ッド	DDO 
ッハ	HHA	ッバ	BBA	ッパ	PPA	ッヒ	HHI 
ッヒャ	HHYA	ッヒュ	HHYU	ッヒョ	HHYO	ッビ	BBI 
ッビャ	BBYA	ッビュ	BBYU	ッビョ	BBYO	ッピ	PPI 
ッピャ	PPYA	ッピュ	PPYU	ッピョ	PPYO	ッフ	HHU 
ッファ	FFA	ッフィ	FFI	ッフェ	FFE	ッフォ	FFO 
ッブ	BBU	ップ	PPU	ッヘ	HHE	ッベ	BBE	ッペ    PPE
ッホ	HHO	ッボ	BBO	ッポ	PPO	ッヤ	YYA	ッユ	YYU 
ッヨ	YYO	ッラ	RRA	ッリ	RRI	ッリャ	RRYA 
ッリュ	RRYU	ッリョ	RRYO	ッル	RRU	ッレ	RRE 
ッロ	RRO 

ツ	TU	ヅ	DU	テ	TE	デ	DE	ト	TO
ド	DO 

ナ	NA	ニ	NI	ニャ	NYA	ニュ	NYU	ニョ	NYO 
ヌ	NU	ネ	NE	ノ	NO 

ハ	HA	バ	BA	パ	PA	ヒ	HI	ヒャ	HYA 
ヒュ	HYU	ヒョ	HYO	ビ	BI	ビャ	BYA	ビュ	BYU 
ビョ	BYO	ピ	PI	ピャ	PYA	ピュ	PYU	ピョ	PYO 
フ	HU	ファ	FA	フィ	FI	フェ	FE	フォ	FO 
ブ	BU	プ	PU	ヘ	HE	ベ	BE	ペ	PE
ホ	HO	ボ	BO	ポ	PO 

マ	MA	ミ	MI	ミャ	MYA	ミュ	MYU	ミョ	MYO 
ム	MU	メ	ME	モ	MO 

ャ	XYA	ヤ	YA	ュ	XYU	ユ	YU	ョ	XYO
ヨ	YO

ラ	RA	リ	RI	リャ	RYA	リュ	RYU	リョ	RYO 
ル	RU	レ	RE	ロ	RO 

ヮ	XWA	ワ	WA	ヰ	WI	ヱ	WE
ヲ	WO	ン	N 

ン     N'
ディ   DYI
ー     -
チェ    TYE
ッチェ	TTYE
ジェ	ZYE
"

  HEPBURNTAB = "\
ぁ	xa	あ	a	ぃ	xi	い	i	ぅ	xu
う	u	う゛	vu	う゛ぁ	va	う゛ぃ	vi	う゛ぇ	ve
う゛ぉ	vo	ぇ	xe	え	e	ぉ	xo	お	o
	

か	ka	が	ga	き	ki	きゃ	kya	きゅ	kyu
きょ	kyo	ぎ	gi	ぎゃ	gya	ぎゅ	gyu	ぎょ	gyo
く	ku	ぐ	gu	け	ke	げ	ge	こ	ko
ご	go	

さ	sa	ざ	za	し	shi	しゃ	sha	しゅ	shu
しょ	sho	じ	ji	じゃ	ja	じゅ	ju	じょ	jo
す	su	ず	zu	せ	se	ぜ	ze	そ	so
ぞ	zo

た	ta	だ	da	ち	chi	ちゃ	cha	ちゅ	chu
ちょ	cho	ぢ	di	ぢゃ	dya	ぢゅ	dyu	ぢょ	dyo

っ	xtsu	
っう゛	vvu	っう゛ぁ	vva	っう゛ぃ	vvi	
っう゛ぇ	vve	っう゛ぉ	vvo	
っか	kka	っが	gga	っき	kki	っきゃ	kkya	
っきゅ	kkyu	っきょ	kkyo	っぎ	ggi	っぎゃ	ggya	
っぎゅ	ggyu	っぎょ	ggyo	っく	kku	っぐ	ggu	
っけ	kke	っげ	gge	っこ	kko	っご	ggo	っさ	ssa
っざ	zza	っし	sshi	っしゃ	ssha	
っしゅ	sshu	っしょ	ssho	
っじ	jji	っじゃ	jja	っじゅ	jju	っじょ	jjo	
っす	ssu	っず	zzu	っせ	sse	っぜ	zze	っそ	sso
っぞ	zzo	った	tta	っだ	dda	っち	cchi	
っちゃ	ccha	っちゅ	cchu	っちょ	ccho	っぢ	ddi	
っぢゃ	ddya	っぢゅ	ddyu	っぢょ	ddyo	っつ	ttsu	
っづ	ddu	って	tte	っで	dde	っと	tto	っど	ddo
っは	hha	っば	bba	っぱ	ppa	っひ	hhi	
っひゃ	hhya	っひゅ	hhyu	っひょ	hhyo	っび	bbi	
っびゃ	bbya	っびゅ	bbyu	っびょ	bbyo	っぴ	ppi	
っぴゃ	ppya	っぴゅ	ppyu	っぴょ	ppyo	っふ	ffu	
っふぁ	ffa	っふぃ	ffi	っふぇ	ffe	っふぉ	ffo	
っぶ	bbu	っぷ	ppu	っへ	hhe	っべ	bbe	っぺ	ppe
っほ	hho	っぼ	bbo	っぽ	ppo	っや	yya	っゆ	yyu
っよ	yyo	っら	rra	っり	rri	っりゃ	rrya	
っりゅ	rryu	っりょ	rryo	っる	rru	っれ	rre	
っろ	rro	

つ	tsu	づ	du	て	te	で	de	と	to
ど	do	

な	na	に	ni	にゃ	nya	にゅ	nyu	にょ	nyo
ぬ	nu	ね	ne	の	no	

は	ha	ば	ba	ぱ	pa	ひ	hi	ひゃ	hya
ひゅ	hyu	ひょ	hyo	び	bi	びゃ	bya	びゅ	byu
びょ	byo	ぴ	pi	ぴゃ	pya	ぴゅ	pyu	ぴょ	pyo
ふ	fu	ふぁ	fa	ふぃ	fi	ふぇ	fe	ふぉ	fo
ぶ	bu	ぷ	pu	へ	he	べ	be	ぺ	pe
ほ	ho	ぼ	bo	ぽ	po	

ま	ma	み	mi	みゃ	mya	みゅ	myu	みょ	myo
む	mu	め	me	も	mo

ゃ	xya	や	ya	ゅ	xyu	ゆ	yu	ょ	xyo
よ	yo	

ら	ra	り	ri	りゃ	rya	りゅ	ryu	りょ	ryo
る	ru	れ	re	ろ	ro	

ゎ	xwa	わ	wa	ゐ	wi	ゑ	we
を	wo	ん	n	

ん     n'
でぃ   dyi
ー     -
ちぇ    che
っちぇ	cche
じぇ	je

ァ	XA	ア	A	ィ	XI	イ	I	ゥ	XU
ウ	U	ウ゛	VU	ウ゛ァ	VA	ウ゛ィ	VI	ウ゛ェ	VE
ウ゛ォ	VO	ェ	XE	エ	E	ォ	XO	オ	O
	

カ	KA	ガ	GA	キ	KI	キャ	KYA	キュ	KYU
キョ	KYO	ギ	GI	ギャ	GYA	ギュ	GYU	ギョ	GYO
ク	KU	グ	GU	ケ	KE	ゲ	GE	コ	KO
ゴ	GO	

サ	SA	ザ	ZA	シ	SHI	シャ	SHA	シュ	SHU
ショ	SHO	ジ	JI	ジャ	JA	ジュ	JU	ジョ	JO
ス	SU	ズ	ZU	セ	SE	ゼ	ZE	ソ	SO
ゾ	ZO

タ	TA	ダ	DA	チ	CHI	チャ	CHA	チュ	CHU
チョ	CHO	ヂ	DI	ヂャ	DYA	ヂュ	DYU	ヂョ	DYO

ッ	XTSU	
ッウ゛	VVU	ッウ゛ァ	VVA	ッウ゛ィ	VVI	
ッウ゛ェ	VVE	ッウ゛ォ	VVO	
ッカ	KKA	ッガ	GGA	ッキ	KKI	ッキャ	KKYA	
ッキュ	KKYU	ッキョ	KKYO	ッギ	GGI	ッギャ	GGYA	
ッギュ	GGYU	ッギョ	GGYO	ック	KKU	ッグ	GGU	
ッケ	KKE	ッゲ	GGE	ッコ	KKO	ッゴ	GGO	ッサ	SSA
ッザ	ZZA	ッシ	SSHI	ッシャ	SSHA	
ッシュ	SSHU	ッショ	SSHO	
ッジ	JJI	ッジャ	JJA	ッジュ	JJU	ッジョ	JJO	
ッス	SSU	ッズ	ZZU	ッセ	SSE	ッゼ	ZZE	ッソ	SSO
ッゾ	ZZO	ッタ	TTA	ッダ	DDA	ッチ	CCHI	
ッチャ	CCHA	ッチュ	CCHU	ッチョ	CCHO	ッヂ	DDI	
ッヂャ	DDYA	ッヂュ	DDYU	ッヂョ	DDYO	ッツ	TTSU	
ッヅ	DDU	ッテ	TTE	ッデ	DDE	ット	TTO	ッド	DDO
ッハ	HHA	ッバ	BBA	ッパ	PPA	ッヒ	HHI	
ッヒャ	HHYA	ッヒュ	HHYU	ッヒョ	HHYO	ッビ	BBI	
ッビャ	BBYA	ッビュ	BBYU	ッビョ	BBYO	ッピ	PPI	
ッピャ	PPYA	ッピュ	PPYU	ッピョ	PPYO	ッフ	FFU	
ッファ	FFA	ッフィ	FFI	ッフェ	FFE	ッフォ	FFO	
ッブ	BBU	ップ	PPU	ッヘ	HHE	ッベ	BBE	ッペ	PPE
ッホ	HHO	ッボ	BBO	ッポ	PPO	ッヤ	YYA	ッユ	YYU
ッヨ	YYO	ッラ	RRA	ッリ	RRI	ッリャ	RRYA	
ッリュ	RRYU	ッリョ	RRYO	ッル	RRU	ッレ	RRE	
ッロ	RRO	

ツ	TSU	ヅ	DU	テ	TE	デ	DE	ト	TO
ド	DO	

ナ	NA	ニ	NI	ニャ	NYA	ニュ	NYU	ニョ	NYO
ヌ	NU	ネ	NE	ノ	NO	

ハ	HA	バ	BA	パ	PA	ヒ	HI	ヒャ	HYA
ヒュ	HYU	ヒョ	HYO	ビ	BI	ビャ	BYA	ビュ	BYU
ビョ	BYO	ピ	PI	ピャ	PYA	ピュ	PYU	ピョ	PYO
フ	FU	ファ	FA	フィ	FI	フェ	FE	フォ	FO
ブ	BU	プ	PU	ヘ	HE	ベ	BE	ペ	PE
ホ	HO	ボ	BO	ポ	PO	

マ	MA	ミ	MI	ミャ	MYA	ミュ	MYU	ミョ	MYO
ム	MU	メ	ME	モ	MO

ャ	XYA	ヤ	YA	ュ	XYU	ユ	YU	ョ	XYO
ヨ	YO	

ラ	RA	リ	RI	リャ	RYA	リュ	RYU	リョ	RYO
ル	RU	レ	RE	ロ	RO	

ヮ	XWA	ワ	WA	ヰ	WI	ヱ	WE
ヲ	WO	ン	N	

ン     N'
ディ   DYI
ー     -
チェ    CHE
ッチェ	CCHE
ジェ	JE
"

  PUNCTUATION = "\
、	,	。	.
「	[	」	]	・	/
"

	ROMKAN = (romakana = Hash.new
			(KUNREITAB + HEPBURNTAB + PUNCTUATION).split(/\s+/).pairs {|x|
				kana, roma = x
				romakana[roma] = kana
			}
			romakana[" "] = "　"
			romakana)

	# Sort in long order so that a longer Romaji sequence precedes.
	ROMPAT = (rompat = ROMKAN.keys.sort{|a, b| b.length <=> a.length}.join("|")
			rompat.gsub(/([,.\[\]\/ ])/){"\\#{$1}"})
	
	# FIXME: ad hod solution
	# tanni   => tan'i
	# kannji  => kanji
	# hannnou => han'nou
	# hannnya => han'nya
	def normalize_double_n
		self.gsub(/nn/, "n'").gsub(/n\'(?=[^aiueoyn]|$)/, "n")
	end

	# Romaji -> Kana
	# It can handle both Hepburn and Kunrei sequences.
	#def to_kana 
	#  tmp = self.normalize_double_n
	#  tmp.gsub(/(#{ROMPAT})/) { ROMKAN[$1] }
	#end
	
	# The above methods are Ruby/Romkan original for reference.
	# Below are the methods actually used by Hermes/Romkan.
	def to_live_sequence
		tmp = self.normalize_double_n
		tmp.gsub(/(#{ROMPAT})/) do
			if Hermes.kana_main_set == :kana
				main = ROMKAN[$1]
				mini = $1
			else
				main = $1
				mini = ROMKAN[$1]
			end
			"\\一[{0}#{main},#{mini}]{0}"
		end
	end
	
	# This works only for a single kana character with normalized double ns
	def to_kana
		ROMKAN[self]
	end
end