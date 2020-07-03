=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
	Name "Hermes configuration (face graphics)"
	Configuration for faces. If you removed the face tag, you can remove this
	script as well.
=end
class Hermes
  # Here you can specify which "special commands" the \f tag allows.
  # E.g., \f[normal] wil be translated to \f[1], and so on.
  FACE_ALIASES = {
    "normal" => 1, "happy" => 2, "sad" => 3, "angry" => 4
  }.freeze

  # The following settings are the defaults for the \f command and can be
  # changed per-message. See documentation for \f command.
  module Face                    # Configuration for face graphics
    HEIGHT = 128                   # Height of faces in facesets (pixels)
    POSITION = :left               # Position of face graphics (:left/:right)
    MIRROR = false                 # Draw face graphics flipped (true/false)
    module Animation
      SPEED = 2                      # Animation speed of animated faces (>0)
      MODE = :cycle                  # Determines wather the animation frames
                                     # are cycled uni- or bidirectionally
                                     # (:cycle or :seesaw)
      PAUSE = false                  # Pause animation with message (true/false)
    end
  end
end