=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes configuration (text effects)"
	Configuration for text effects. If you removed the text effects script, you
	can remove this script as well. Likewise, you can use the text effects script
	without needing this script or any other part of Hermes.
=end
class Hermes
	module GlobalText                # Global Font / Style Configuration
		TEXTURE = nil                    # Text texture ("filename" or nil)
		# The syntax of the following values is [strength(, color)?]
		OUTLINE = [2]                    # Text outline
		SHADOW  = [2]                    # Text shadow
	end
	module Message::Text           # Configuration for text in message box
		TEXTURE = :default             # Text texture ("filename"/:default/:none)
		# The syntax of the following values is [strength(, color)?] or :default
		OUTLINE = :default             # Text outline
		SHADOW  = :default             # Text shadow
	end
	if defined? Name
		module Name::Text            # Configuration for text in name box
			TEXTURE = :default           # Text texture ("filename"/:default/:none)
			# The syntax of the following values is [strength(, color)?] or :default
			OUTLINE = :default           # Text outline
			SHADOW  = :default           # Text shadow
		end
	end
	# This is needed so that the settings are properly set up
	class ::TextEffect; end
end