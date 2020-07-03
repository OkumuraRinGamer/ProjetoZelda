=begin script                    ■ Hermes - Hermes Extends RMXP's MEssage System
   Name "Hermes other classes (text effects)"
   This script implements 3 new text effects for RGSS: shadow, outline and
   texture. They can be used without Hermes, but you should consider copying the
   text effects script from config folder as well, for convenience.
   To use text effects call
      Bitmap#draw_text(rect, string, align, shadow, outline, texture),
   where rect can be replaced with x, y, width, height, align is 0, 1 or 2,
   shadow and outline are TextEffect objects (or nil) and texture is a filename
   or nil. To create a TextEffect object, do
      TextEffect.new(size, color),
   where size is shadow offset / outline width and color is a Color.

   Alias "Bitmap#draw_text => hermes_old_dt" <- this is a very helpful feature of
                                                Inserter!
=end

# Text effects "shadow" and "outline" for use with Hermes.
# Can also be used as a standalone script.

class TextEffect
   attr_accessor :active, :size, :color
   def initialize(size = 1, color = Color.new(0, 0, 0, 128))
      @size = size.to_i
      if color.is_a? Color
         @color = color
      else
         @color = Color.new(*color)
      end
      @active = (@size > 0)
   end

   if defined? Hermes
      @@global_outline = self.new(*Hermes::GlobalText::OUTLINE)
      @@global_shadow = self.new(*Hermes::GlobalText::SHADOW)
      @@global_texture = Hermes::GlobalText::TEXTURE
   else
      @@global_outline = self.new(0)
      @@global_shadow = self.new(1)
      @@global_texture = nil
   end
   def self.global_outline() @@global_outline.dup end
   def self.global_shadow()  @@global_shadow.dup  end
   def self.global_texture() @@global_texture     end

   #--------------------------------------------------------------------------

   def active?
      return (@active and @size > 0)
   end

   #------------------------------------------------------------------------

   # Dup should also dup the effects
   def dup
      duplicate = super
      duplicate.color = @color.dup
      duplicate
   end
end

class Font
   def self.method_missing sym, *args
      # Load / save old JRGSS default
      if sym.to_s[/default_(name|size|color|bold|italic)(=)?/]
         unless $2 or args.empty?
            raise ArgumentError, "wrong number of arguments (#{args.length} for 0)."
         end
         eval "$font#{$1 == 'name' ? 'face' : $1}#{$2 ? ' = args[0]' : ''}"
      else
         # Throw NoMethodError as usual
         super
      end
   end

   if defined? Hermes
      self.default_name = Hermes::GlobalText::NAME
      self.default_size = Hermes::GlobalText::SIZE
      self.default_color = Hermes::GlobalText::COLOR
      self.default_bold = Hermes::GlobalText::BOLD
      self.default_italic = Hermes::GlobalText::ITALIC
   end

   #------------------------------------------------------------------------

   # Make sure fonts can be loaded (for Hermes' backwards compatibility)
   def marshal_load(hash)
      initialize()
      hash.each do |sym, value|
         instance_variable_set "@#{sym}", value
      end
   end
end

class Color
   def marshal_load(hash)
      Color._load hash
   end
end

class Bitmap
   def draw_text(x, y, *args)
      return draw_text(x.x, x.y, x.width, x.height, y, *args) if x.is_a? Rect
      args, shadow, outline, texture = args.slice!(0,4), *args
      shadow  = (shadow  or TextEffect.global_shadow)
      outline = (outline or TextEffect.global_outline)
      texture = (texture or TextEffect.global_texture)
      # RGSS is so dumb.
      # RGSS is really dumb.
      # For real.
      oldr, oldg, oldb, olda =
            font.color.red, font.color.green, font.color.blue, font.color.alpha
      if shadow.active?
         font.color = shadow.color
         size = shadow.size
         hermes_old_dt(x + size, y + size, *args)
      end
      if outline.active?
         size = outline.size
         # Create buffer to paint in
         buffer = Bitmap.new(args[0] + 2*size, 2*args[1])
         buffer.font = font.dup
         buffer.font.color = outline.color
         # Draw text *once*
         buffer.hermes_old_dt(0, 0, *args)
         # Copy vertically
         src_rect = Rect.new(0,0,args[0],args[1])
         for now_x in 0..size-1
            alpha = (255*((1-now_x.quo(size)**0.3))).round
            buffer.blt(size - now_x - 1, args[1], buffer, src_rect, alpha)
            buffer.blt(size + now_x + 1, args[1], buffer, src_rect, alpha)
         end
         src_rect.y += args[1]
         src_rect.width += 2*size
         for now_y in 0..size-1
            now_size = now_y.abs - 1
             alpha = (255*((1-now_y.quo(size)**0.3))).round
            blt(x-size, y - now_y - 1, buffer, src_rect, alpha)
            blt(x-size, y + now_y + 1, buffer, src_rect, alpha)
         end
         buffer.dispose
      end
      font.color.set(oldr, oldg, oldb, olda)
      hermes_old_dt(x, y, *args)
      if texture
         width, height = args
         texture = RPG::Cache.picture(texture)
         pixel = color = nil
         for ox in 0...width-1
            for oy in 0..height-1
               pixel = get_pixel(x + ox, y + oy)
               if pixel.alpha > 0
                  color = texture.get_pixel(ox % texture.width, oy % texture.height)
                  color.set(
                     Math.sqrt(pixel.red * color.red).round,
                     Math.sqrt(pixel.green * color.green).round,
                     Math.sqrt(pixel.blue * color.blue).round,
                     Math.sqrt(pixel.alpha * color.alpha).round
                  )
                  set_pixel(x + ox, y + oy, color)
               end
            end
         end
      end
   end
end