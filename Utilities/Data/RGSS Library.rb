#===============================================================================
# RGSS Library
#===============================================================================
# Author: Maximusmaxy
# Version 1.0: 8/4/2012
# Thanks to:
# RGSS Reference Manual
# - RPG Module
# http://www.hbgames.org/forums/viewtopic.php?style=26&f=11&t=49838
# - Table/Color/Tone Class
#===============================================================================
#
# Introduction:
# Allows you to require allot of the built in RGSS methods and classes, it also
# inlcudes a bunch of new classes and methods for you to use and automatically
# loads all the global data eg. $data_weapons, $data_items ect.
#
# New Classes:
# RPG::Maps - a pseudo hash storing all map objects
# RPG::Scripts - a pseudo array storing all scripts in a readable form
#
# New Objects:
# $data_map_infos - an hash of all map info objects
# $data_maps - an instance of RPG::Maps
# $data_scripts - an instance of RPG::Scripts
#
# New Constants:
# RPG::GRAPHICS_EXT - an array of all graphic extensions
# RPG::AUDIO_EXT - an array of all audio extensions
# RPG::RTP_PATHS - an array of all rtp paths
#
# New Methods:
# Table#xsize=(value) - resizes a tables xsize
# value - the new xsize
#
# Table#ysize=(value) - resizes a tables ysize
# value - the new ysize
#
# Table#zsize=(value) - resizes a tables zsize
# value - the new zsize
#
# RPG::location(filename, extension) - returns the files relative Game.exe
#                                      location or rtp location
# filename - the filename you need the location of
# extension - whether or not to automatically add the files extension
#
# RPG::extension(filename) - gets the missing extension of the file
# filename - the filename you need the extension of
# 
# RPG::load_data(filename) - the built in RGSS load_data method
# filename - the location of the file
#
# RPG::save_data(object, filename) - the built in RGSS save_data method
# object - the object you are saving
# filename - the location you are saving to
#
# RPG::load_rpg_data - loads all global data plus maps and scripts
#                      It is called automatically on requirement
#
# RPG::save_rpg_data - saves all global data plus maps and scripts
#
# RPG::filetest(filename, rtp = false) - does a FileTest.file?
# filename - the filename you are testing
# rtp - whether or not you are testing for the RTP aswell
#
# RPG::rtp_filetest(filename) - does a FileTest.file? for RTP
# filename - the filename you are testing
#
# RPG::rename(prev, new, swap = false) - File.rename with optional swap
# prev - the previous filename
# new - the new filename
# swap - whether existing files are swapped or overwritten
#
# RPG::graphic_files(folder) - Returns an array of all the graphic files
#                              in the specified folder
# folder - the folder eg. Characters, Pictures
#
# RPG::audio_files(folder) - Returns an array of all the audio files
#                            in the specified folder
# folder - the folder eg. BGM, BGS, ME, SE
#
# RPG::rtp_graphics(folder) - Returns an array of all RTP graphics
#                             in the specified folder
# folder - the folder eg. Character, Pictures
#
# RPG::rtp_audio(folder) - Returns an array of all RTP audio
#                          in the specified folder
# folder - the folder EG. BGM, BGS, ME, SE
#
#===============================================================================

module RPG

#===============================================================================
# Configuration
#===============================================================================
  #The Root of your Game.exe Folder
  ROOT = '../'
#===============================================================================
# End Configuration
#===============================================================================

end

require 'win32/registry'
require 'zlib'

#===============================================================================
# Table
#===============================================================================

class Table
  attr_accessor :xsize
  attr_accessor :ysize
  attr_accessor :zsize
  attr_accessor :data
  def initialize(x, y = 0, z = 0)
    @dim = 1 + (y > 0 ? 1 : 0) + (z > 0 ? 1 : 0)
    @xsize, @ysize, @zsize = x, [y, 1].max, [z, 1].max
    @data = Array.new(@xsize * @ysize * @zsize, 0)
  end
  
  def [](x, y = 0, z = 0)
    @data[x + y * @xsize + z * @xsize * @ysize]
  end

  def []=(*args)
    x = args[0]
    y = args.size > 2 ? args[1] : 0
    z = args.size > 3 ? args[2] : 0
    v = args.pop
    @data[x + y * @xsize + z * @xsize * @ysize] = v
  end
  
  def xsize=(size)
    resize(*[size, @ysize, @zsize][0, @dim])
  end
  
  def ysize=(size)
    resize(*[@xsize, size, @zsize][0, @dim])
  end
  
  def zsize=(size)
    resize(@xsize, @ysize, size)
  end
  
  def resize(nx, ny = 0, nz = 0)
    @dim = 1 + (ny > 0 ? 1 : 0) + (nz > 0 ? 1 : 0)
    nx, ny, nz = nx, [ny, 1].max, [nz, 1].max
    data = Array.new(nx * ny * nz, 0)
    [@xsize, nx].min.times do |x|
      [@ysize, ny].min.times do |y|
        [@zsize, nz].min.times do |z|
          data[x + y * nx + z * nx * ny] = self[x, y, z]
        end
      end
    end
    self.data = data
    @xsize, @ysize, @zsize = nx, ny, nz
  end
  
  def _dump(d = 0)
    [@dim, @xsize, @ysize, @zsize, @xsize * @ysize * @zsize].pack('LLLLL') <<
    @data.pack("S#{@xsize * @ysize * @zsize}")
  end
  
  def self._load(s)
    size, nx, ny, nz, items = *s[0, 20].unpack('LLLLL')
    t = Table.new(*[nx, ny, nz][0,size])
    t.data = s[20, items * 2].unpack("S#{items}")
    t
  end
end

#===============================================================================
# Color
#===============================================================================

class Color
  attr_reader :red
  attr_reader :green
  attr_reader :blue
  attr_reader :alpha
  def initialize(r, g, b, a = 255.0)
    self.red = r.to_f
    self.green = g.to_f
    self.blue = b.to_f
    self.alpha = a.to_f
  end
  
  def set(r, g, b, a = 255.0)
    self.red = r.to_f
    self.green = g.to_f
    self.blue = b.to_f
    self.alpha = a.to_f
  end
  
  def red=(val)
    @red = [[val.to_f, 0.0].max, 255.0].min
  end
  
  def green=(val)
    @green = [[val.to_f, 0.0].max, 255.0].min
  end
  
  def blue=(val)
    @blue = [[val.to_f, 0.0].max, 255.0].min
  end
  
  def alpha=(val)
    @alpha = [[val.to_f, 0.0].max, 255.0].min
  end
  
  def color
    Color.new(@red, @green, @blue, @alpha)
  end
  
  def _dump(d = 0)
    [@red, @green, @blue, @alpha].pack('d4')
  end
  
  def self._load(s)
    Color.new(*s.unpack('d4'))
  end
end

#===============================================================================
# Tone
#===============================================================================

class Tone
  attr_reader :red
  attr_reader :green
  attr_reader :blue
  attr_reader :grey
  def initialize(r, g, b, a = 0.0)
    self.red = r.to_f
    self.green = g.to_f
    self.blue = b.to_f
    self.gray = a.to_f
  end
  
  def set(r, g, b, a = 0.0)
    self.red = r.to_f
    self.green = g.to_f
    self.blue = b.to_f
    self.gray = a.to_f
  end
  
  def color
    Color.new(@red, @green, @blue, @gray)
  end
  
  def _dump(d = 0)
    [@red, @green, @blue, @gray].pack('d4')
  end
  
  def self._load(s)
    Tone.new(*s.unpack('d4'))
  end

  def red=(val)
    @red    = [[val.to_f, -255.0].max, 255.0].min
  end
  
  def green=(val)
    @green = [[val.to_f, -255.0].max, 255.0].min
  end
  
  def blue=(val)
    @blue   = [[val.to_f, -255.0].max, 255.0].min
  end
  
  def gray=(val)
    @gray   = [[val.to_f, 0.0].max, 255.0].min
  end
end

#===============================================================================
# RPG
#===============================================================================

module RPG
  
  #===============================================================================
  # RPG::Map
  #===============================================================================
  
  class Map
    def initialize(width, height)
      @tileset_id = 1
      @width = width
      @height = height
      @autoplay_bgm = false
      @bgm = RPG::AudioFile.new
      @autoplay_bgs = false
      @bgs = RPG::AudioFile.new("", 80)
      @encounter_list = []
      @encounter_step = 30
      @data = Table.new(width, height, 3)
      @events = {}
    end
    attr_accessor :tileset_id
    attr_accessor :width
    attr_accessor :height
    attr_accessor :autoplay_bgm
    attr_accessor :bgm
    attr_accessor :autoplay_bgs
    attr_accessor :bgs
    attr_accessor :encounter_list
    attr_accessor :encounter_step
    attr_accessor :data
    attr_accessor :events
  end
  
  #===============================================================================
  # RPG::MapInfo
  #===============================================================================
  
  class MapInfo
    def initialize
      @name = ""
      @parent_id = 0
      @order = 0
      @expanded = false
      @scroll_x = 0
      @scroll_y = 0
    end
    attr_accessor :name
    attr_accessor :parent_id
    attr_accessor :order
    attr_accessor :expanded
    attr_accessor :scroll_x
    attr_accessor :scroll_y
  end
  
  #===============================================================================
  # RPG::Event
  #===============================================================================
  
  class Event
    class Page
      class Condition
        def initialize
          @switch1_valid = false
          @switch2_valid = false
          @variable_valid = false
          @self_switch_valid = false
          @switch1_id = 1
          @switch2_id = 1
          @variable_id = 1
          @variable_value = 0
          @self_switch_ch = "A"
        end
        attr_accessor :switch1_valid
        attr_accessor :switch2_valid
        attr_accessor :variable_valid
        attr_accessor :self_switch_valid
        attr_accessor :switch1_id
        attr_accessor :switch2_id
        attr_accessor :variable_id
        attr_accessor :variable_value
        attr_accessor :self_switch_ch
      end

      class Graphic
        def initialize
          @tile_id = 0
          @character_name = ""
          @character_hue = 0
          @direction = 2
          @pattern = 0
          @opacity = 255
          @blend_type = 0
        end
        attr_accessor :tile_id
        attr_accessor :character_name
        attr_accessor :character_hue
        attr_accessor :direction
        attr_accessor :pattern
        attr_accessor :opacity
        attr_accessor :blend_type
      end
      
      def initialize
        @condition = RPG::Event::Page::Condition.new
        @graphic = RPG::Event::Page::Graphic.new
        @move_type = 0
        @move_speed = 3
        @move_frequency = 3
        @move_route = RPG::MoveRoute.new
        @walk_anime = true
        @step_anime = false
        @direction_fix = false
        @through = false
        @always_on_top = false
        @trigger = 0
        @list = [RPG::EventCommand.new]
      end
      attr_accessor :condition
      attr_accessor :graphic
      attr_accessor :move_type
      attr_accessor :move_speed
      attr_accessor :move_frequency
      attr_accessor :move_route
      attr_accessor :walk_anime
      attr_accessor :step_anime
      attr_accessor :direction_fix
      attr_accessor :through
      attr_accessor :always_on_top
      attr_accessor :trigger
      attr_accessor :list
    end
    
    def initialize(x, y)
      @id = 0
      @name = ""
      @x = x
      @y = y
      @pages = [RPG::Event::Page.new]
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :x
    attr_accessor :y
    attr_accessor :pages
  end
  
  #===============================================================================
  # RPG::EventCommand
  #===============================================================================
  
  class EventCommand
    def initialize(code = 0, indent = 0, parameters = [])
      @code = code
      @indent = indent
      @parameters = parameters
    end
    attr_accessor :code
    attr_accessor :indent
    attr_accessor :parameters
  end
  
  #===============================================================================
  # RPG::MoveRoute
  #===============================================================================
  
  class MoveRoute
    def initialize
      @repeat = true
      @skippable = false
      @list = [RPG::MoveCommand.new]
    end
    attr_accessor :repeat
    attr_accessor :skippable
    attr_accessor :list
  end
  
  #===============================================================================
  # RPG::MoveCommand
  #===============================================================================
  
  class MoveCommand
    def initialize(code = 0, parameters = [])
      @code = code
      @parameters = parameters
    end
    attr_accessor :code
    attr_accessor :parameters
  end
  
  #===============================================================================
  # RPG::Actor
  #===============================================================================
  
  class Actor
    def initialize
      @id = 0
      @name = ""
      @class_id = 1
      @initial_level = 1
      @final_level = 99
      @exp_basis = 30
      @exp_inflation = 30
      @character_name = ""
      @character_hue = 0
      @battler_name = ""
      @battler_hue = 0
      @parameters = Table.new(6,100)
      for i in 1..99
        @parameters[0,i] = 500+i*50
        @parameters[1,i] = 500+i*50
        @parameters[2,i] = 50+i*5
        @parameters[3,i] = 50+i*5
        @parameters[4,i] = 50+i*5
        @parameters[5,i] = 50+i*5
      end
      @weapon_id = 0
      @armor1_id = 0
      @armor2_id = 0
      @armor3_id = 0
      @armor4_id = 0
      @weapon_fix = false
      @armor1_fix = false
      @armor2_fix = false
      @armor3_fix = false
      @armor4_fix = false
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :class_id
    attr_accessor :initial_level
    attr_accessor :final_level
    attr_accessor :exp_basis
    attr_accessor :exp_inflation
    attr_accessor :character_name
    attr_accessor :character_hue
    attr_accessor :battler_name
    attr_accessor :battler_hue
    attr_accessor :parameters
    attr_accessor :weapon_id
    attr_accessor :armor1_id
    attr_accessor :armor2_id
    attr_accessor :armor3_id
    attr_accessor :armor4_id
    attr_accessor :weapon_fix
    attr_accessor :armor1_fix
    attr_accessor :armor2_fix
    attr_accessor :armor3_fix
    attr_accessor :armor4_fix
  end

  #===============================================================================
  # RPG::Class
  #===============================================================================
  
  class Class
    class Learning
      def initialize
        @level = 1
        @skill_id = 1
      end
      attr_accessor :level
      attr_accessor :skill_id
    end
    def initialize
      @id = 0
      @name = ""
      @position = 0
      @weapon_set = []
      @armor_set = []
      @element_ranks = Table.new(1)
      @state_ranks = Table.new(1)
      @learnings = []
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :position
    attr_accessor :weapon_set
    attr_accessor :armor_set
    attr_accessor :element_ranks
    attr_accessor :state_ranks
    attr_accessor :learnings
  end
  
  #===============================================================================
  # RPG::Skill
  #===============================================================================
  
  class Skill
    def initialize
      @id = 0
      @name = ""
      @icon_name = ""
      @description = ""
      @scope = 0
      @occasion = 1
      @animation1_id = 0
      @animation2_id = 0
      @menu_se = RPG::AudioFile.new("", 80)
      @common_event_id = 0
      @sp_cost = 0
      @power = 0
      @atk_f = 0
      @eva_f = 0
      @str_f = 0
      @dex_f = 0
      @agi_f = 0
      @int_f = 100
      @hit = 100
      @pdef_f = 0
      @mdef_f = 100
      @variance = 15
      @element_set = []
      @plus_state_set = []
      @minus_state_set = []
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :icon_name
    attr_accessor :description
    attr_accessor :scope
    attr_accessor :occasion
    attr_accessor :animation1_id
    attr_accessor :animation2_id
    attr_accessor :menu_se
    attr_accessor :common_event_id
    attr_accessor :sp_cost
    attr_accessor :power
    attr_accessor :atk_f
    attr_accessor :eva_f
    attr_accessor :str_f
    attr_accessor :dex_f
    attr_accessor :agi_f
    attr_accessor :int_f
    attr_accessor :hit
    attr_accessor :pdef_f
    attr_accessor :mdef_f
    attr_accessor :variance
    attr_accessor :element_set
    attr_accessor :plus_state_set
    attr_accessor :minus_state_set
  end
  
  #===============================================================================
  # RPG::Item
  #===============================================================================
  
  class Item
    def initialize
      @id = 0
      @name = ""
      @icon_name = ""
      @description = ""
      @scope = 0
      @occasion = 0
      @animation1_id = 0
      @animation2_id = 0
      @menu_se = RPG::AudioFile.new("", 80)
      @common_event_id = 0
      @price = 0
      @consumable = true
      @parameter_type = 0
      @parameter_points = 0
      @recover_hp_rate = 0
      @recover_hp = 0
      @recover_sp_rate = 0
      @recover_sp = 0
      @hit = 100
      @pdef_f = 0
      @mdef_f = 0
      @variance = 0
      @element_set = []
      @plus_state_set = []
      @minus_state_set = []
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :icon_name
    attr_accessor :description
    attr_accessor :scope
    attr_accessor :occasion
    attr_accessor :animation1_id
    attr_accessor :animation2_id
    attr_accessor :menu_se
    attr_accessor :common_event_id
    attr_accessor :price
    attr_accessor :consumable
    attr_accessor :parameter_type
    attr_accessor :parameter_points
    attr_accessor :recover_hp_rate
    attr_accessor :recover_hp
    attr_accessor :recover_sp_rate
    attr_accessor :recover_sp
    attr_accessor :hit
    attr_accessor :pdef_f
    attr_accessor :mdef_f
    attr_accessor :variance
    attr_accessor :element_set
    attr_accessor :plus_state_set
    attr_accessor :minus_state_set
  end
  
  #===============================================================================
  # RPG::Weapon
  #===============================================================================
  
  class Weapon
    def initialize
      @id = 0
      @name = ""
      @icon_name = ""
      @description = ""
      @animation1_id = 0
      @animation2_id = 0
      @price = 0
      @atk = 0
      @pdef = 0
      @mdef = 0
      @str_plus = 0
      @dex_plus = 0
      @agi_plus = 0
      @int_plus = 0
      @element_set = []
      @plus_state_set = []
      @minus_state_set = []
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :icon_name
    attr_accessor :description
    attr_accessor :animation1_id
    attr_accessor :animation2_id
    attr_accessor :price
    attr_accessor :atk
    attr_accessor :pdef
    attr_accessor :mdef
    attr_accessor :str_plus
    attr_accessor :dex_plus
    attr_accessor :agi_plus
    attr_accessor :int_plus
    attr_accessor :element_set
    attr_accessor :plus_state_set
    attr_accessor :minus_state_set
  end

  #===============================================================================
  # RGP::Armor
  #===============================================================================
  
  class Armor
    def initialize
      @id = 0
      @name = ""
      @icon_name = ""
      @description = ""
      @kind = 0
      @auto_state_id = 0
      @price = 0
      @pdef = 0
      @mdef = 0
      @eva = 0
      @str_plus = 0
      @dex_plus = 0
      @agi_plus = 0
      @int_plus = 0
      @guard_element_set = []
      @guard_state_set = []
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :icon_name
    attr_accessor :description
    attr_accessor :kind
    attr_accessor :auto_state_id
    attr_accessor :price
    attr_accessor :pdef
    attr_accessor :mdef
    attr_accessor :eva
    attr_accessor :str_plus
    attr_accessor :dex_plus
    attr_accessor :agi_plus
    attr_accessor :int_plus
    attr_accessor :guard_element_set
    attr_accessor :guard_state_set
  end
  
  #===============================================================================
  # RPG::Enemy
  #===============================================================================
  
  class Enemy
    class Action
      def initialize
        @kind = 0
        @basic = 0
        @skill_id = 1
        @condition_turn_a = 0
        @condition_turn_b = 1
        @condition_hp = 100
        @condition_level = 1
        @condition_switch_id = 0
        @rating = 5
      end
      attr_accessor :kind
      attr_accessor :basic
      attr_accessor :skill_id
      attr_accessor :condition_turn_a
      attr_accessor :condition_turn_b
      attr_accessor :condition_hp
      attr_accessor :condition_level
      attr_accessor :condition_switch_id
      attr_accessor :rating
    end

    def initialize
      @id = 0
      @name = ""
      @battler_name = ""
      @battler_hue = 0
      @maxhp = 500
      @maxsp = 500
      @str = 50
      @dex = 50
      @agi = 50
      @int = 50
      @atk = 100
      @pdef = 100
      @mdef = 100
      @eva = 0
      @animation1_id = 0
      @animation2_id = 0
      @element_ranks = Table.new(1)
      @state_ranks = Table.new(1)
      @actions = [RPG::Enemy::Action.new]
      @exp = 0
      @gold = 0
      @item_id = 0
      @weapon_id = 0
      @armor_id = 0
      @treasure_prob = 100
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :battler_name
    attr_accessor :battler_hue
    attr_accessor :maxhp
    attr_accessor :maxsp
    attr_accessor :str
    attr_accessor :dex
    attr_accessor :agi
    attr_accessor :int
    attr_accessor :atk
    attr_accessor :pdef
    attr_accessor :mdef
    attr_accessor :eva
    attr_accessor :animation1_id
    attr_accessor :animation2_id
    attr_accessor :element_ranks
    attr_accessor :state_ranks
    attr_accessor :actions
    attr_accessor :exp
    attr_accessor :gold
    attr_accessor :item_id
    attr_accessor :weapon_id
    attr_accessor :armor_id
    attr_accessor :treasure_prob
  end
  
  #===============================================================================
  # RPG::Troop
  #===============================================================================
  
  class Troop
    class Member
      def initialize
        @enemy_id = 1
        @x = 0
        @y = 0
        @hidden = false
        @immortal = false
      end
      attr_accessor :enemy_id
      attr_accessor :x
      attr_accessor :y
      attr_accessor :hidden
      attr_accessor :immortal
    end
    class Page
      class Condition
        def initialize
          @turn_valid = false
          @enemy_valid = false
          @actor_valid = false
          @switch_valid = false
          @turn_a = 0
          @turn_b = 0
          @enemy_index = 0
          @enemy_hp = 50
          @actor_id = 1
          @actor_hp = 50
          @switch_id = 1
        end
        attr_accessor :turn_valid
        attr_accessor :enemy_valid
        attr_accessor :actor_valid
        attr_accessor :switch_valid
        attr_accessor :turn_a
        attr_accessor :turn_b
        attr_accessor :enemy_index
        attr_accessor :enemy_hp
        attr_accessor :actor_id
        attr_accessor :actor_hp
        attr_accessor :switch_id
      end

      def initialize
        @condition = RPG::Troop::Page::Condition.new
        @span = 0
        @list = [RPG::EventCommand.new]
      end
      attr_accessor :condition
      attr_accessor :span
      attr_accessor :list
    end
    def initialize
      @id = 0
      @name = ""
      @members = []
      @pages = [RPG::BattleEventPage.new]
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :members
    attr_accessor :pages
  end
  
  #===============================================================================
  # RPG::State
  #===============================================================================

  class State
    def initialize
      @id = 0
      @name = ""
      @animation_id = 0
      @restriction = 0
      @nonresistance = false
      @zero_hp = false
      @cant_get_exp = false
      @cant_evade = false
      @slip_damage = false
      @rating = 5
      @hit_rate = 100
      @maxhp_rate = 100
      @maxsp_rate = 100
      @str_rate = 100
      @dex_rate = 100
      @agi_rate = 100
      @int_rate = 100
      @atk_rate = 100
      @pdef_rate = 100
      @mdef_rate = 100
      @eva = 0
      @battle_only = true
      @hold_turn = 0
      @auto_release_prob = 0
      @shock_release_prob = 0
      @guard_element_set = []
      @plus_state_set = []
      @minus_state_set = []
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :animation_id
    attr_accessor :restriction
    attr_accessor :nonresistance
    attr_accessor :zero_hp
    attr_accessor :cant_get_exp
    attr_accessor :cant_evade
    attr_accessor :slip_damage
    attr_accessor :rating
    attr_accessor :hit_rate
    attr_accessor :maxhp_rate
    attr_accessor :maxsp_rate
    attr_accessor :str_rate
    attr_accessor :dex_rate
    attr_accessor :agi_rate
    attr_accessor :int_rate
    attr_accessor :atk_rate
    attr_accessor :pdef_rate
    attr_accessor :mdef_rate
    attr_accessor :eva
    attr_accessor :battle_only
    attr_accessor :hold_turn
    attr_accessor :auto_release_prob
    attr_accessor :shock_release_prob
    attr_accessor :guard_element_set
    attr_accessor :plus_state_set
    attr_accessor :minus_state_set
  end
  
  #===============================================================================
  # RPG::Animation
  #===============================================================================
  
  class Animation
    class Frame
      def initialize
        @cell_max = 0
        @cell_data = Table.new(0, 0)
      end
      attr_accessor :cell_max
      attr_accessor :cell_data
    end
    
    class Timing
      def initialize
        @frame = 0
        @se = RPG::AudioFile.new("", 80)
        @flash_scope = 0
        @flash_color = Color.new(255,255,255,255)
        @flash_duration = 5
        @condition = 0
      end
      attr_accessor :frame
      attr_accessor :se
      attr_accessor :flash_scope
      attr_accessor :flash_color
      attr_accessor :flash_duration
      attr_accessor :condition
    end

    def initialize
      @id = 0
      @name = ""
      @animation_name = ""
      @animation_hue = 0
      @position = 1
      @frame_max = 1
      @frames = [RPG::Animation::Frame.new]
      @timings = []
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :animation_name
    attr_accessor :animation_hue
    attr_accessor :position
    attr_accessor :frame_max
    attr_accessor :frames
    attr_accessor :timings
  end
  
  #===============================================================================
  # RPG::Tileset
  #===============================================================================
  
  class Tileset
    def initialize
      @id = 0
      @name = ""
      @tileset_name = ""
      @autotile_names = Array.new(7, "")
      @panorama_name = ""
      @panorama_hue = 0
      @fog_name = ""
      @fog_hue = 0
      @fog_opacity = 64
      @fog_blend_type = 0
      @fog_zoom = 200
      @fog_sx = 0
      @fog_sy = 0
      @battleback_name = ""
      @passages = Table.new(384)
      @priorities = Table.new(384)
      @priorities[0] = 5
      @terrain_tags = Table.new(384)
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :tileset_name
    attr_accessor :autotile_names
    attr_accessor :panorama_name
    attr_accessor :panorama_hue
    attr_accessor :fog_name
    attr_accessor :fog_hue
    attr_accessor :fog_opacity
    attr_accessor :fog_blend_type
    attr_accessor :fog_zoom
    attr_accessor :fog_sx
    attr_accessor :fog_sy
    attr_accessor :battleback_name
    attr_accessor :passages
    attr_accessor :priorities
    attr_accessor :terrain_tags
  end
  
  #===============================================================================
  # RPG::CommonEvent
  #===============================================================================
  
  class CommonEvent
    def initialize
      @id = 0
      @name = ""
      @trigger = 0
      @switch_id = 1
      @list = [RPG::EventCommand.new]
    end
    attr_accessor :id
    attr_accessor :name
    attr_accessor :trigger
    attr_accessor :switch_id
    attr_accessor :list
  end

  #===============================================================================
  # RPG::System
  #===============================================================================
  
  class System
    class Words
      def initialize
        @gold = ""
        @hp = ""
        @sp = ""
        @str = ""
        @dex = ""
        @agi = ""
        @int = ""
        @atk = ""
        @pdef = ""
        @mdef = ""
        @weapon = ""
        @armor1 = ""
        @armor2 = ""
        @armor3 = ""
        @armor4 = ""
        @attack = ""
        @skill = ""
        @guard = ""
        @item = ""
        @equip = ""
      end
      attr_accessor :gold
      attr_accessor :hp
      attr_accessor :sp
      attr_accessor :str
      attr_accessor :dex
      attr_accessor :agi
      attr_accessor :int
      attr_accessor :atk
      attr_accessor :pdef
      attr_accessor :mdef
      attr_accessor :weapon
      attr_accessor :armor1
      attr_accessor :armor2
      attr_accessor :armor3
      attr_accessor :armor4
      attr_accessor :attack
      attr_accessor :skill
      attr_accessor :guard
      attr_accessor :item
      attr_accessor :equip
    end

    class TestBattler
      def initialize
        @actor_id = 1
        @level = 1
        @weapon_id = 0
        @armor1_id = 0
        @armor2_id = 0
        @armor3_id = 0
        @armor4_id = 0
      end
      attr_accessor :actor_id
      attr_accessor :level
      attr_accessor :weapon_id
      attr_accessor :armor1_id
      attr_accessor :armor2_id
      attr_accessor :armor3_id
      attr_accessor :armor4_id
    end
    
    def initialize
      @magic_number = 0
      @party_members = [1]
      @elements = [nil, ""]
      @switches = [nil, ""]
      @variables = [nil, ""]
      @windowskin_name = ""
      @title_name = ""
      @gameover_name = ""
      @battle_transition = ""
      @title_bgm = RPG::AudioFile.new
      @battle_bgm = RPG::AudioFile.new
      @battle_end_me = RPG::AudioFile.new
      @gameover_me = RPG::AudioFile.new
      @cursor_se = RPG::AudioFile.new("", 80)
      @decision_se = RPG::AudioFile.new("", 80)
      @cancel_se = RPG::AudioFile.new("", 80)
      @buzzer_se = RPG::AudioFile.new("", 80)
      @equip_se = RPG::AudioFile.new("", 80)
      @shop_se = RPG::AudioFile.new("", 80)
      @save_se = RPG::AudioFile.new("", 80)
      @load_se = RPG::AudioFile.new("", 80)
      @battle_start_se = RPG::AudioFile.new("", 80)
      @escape_se = RPG::AudioFile.new("", 80)
      @actor_collapse_se = RPG::AudioFile.new("", 80)
      @enemy_collapse_se = RPG::AudioFile.new("", 80)
      @words = RPG::System::Words.new
      @test_battlers = []
      @test_troop_id = 1
      @start_map_id = 1
      @start_x = 0
      @start_y = 0
      @battleback_name = ""
      @battler_name = ""
      @battler_hue = 0
      @edit_map_id = 1
    end
    attr_accessor :magic_number
    attr_accessor :party_members
    attr_accessor :elements
    attr_accessor :switches
    attr_accessor :variables
    attr_accessor :windowskin_name
    attr_accessor :title_name
    attr_accessor :gameover_name
    attr_accessor :battle_transition
    attr_accessor :title_bgm
    attr_accessor :battle_bgm
    attr_accessor :battle_end_me
    attr_accessor :gameover_me
    attr_accessor :cursor_se
    attr_accessor :decision_se
    attr_accessor :cancel_se
    attr_accessor :buzzer_se
    attr_accessor :equip_se
    attr_accessor :shop_se
    attr_accessor :save_se
    attr_accessor :load_se
    attr_accessor :battle_start_se
    attr_accessor :escape_se
    attr_accessor :actor_collapse_se
    attr_accessor :enemy_collapse_se
    attr_accessor :words
    attr_accessor :test_battlers
    attr_accessor :test_troop_id
    attr_accessor :start_map_id
    attr_accessor :start_x
    attr_accessor :start_y
    attr_accessor :battleback_name
    attr_accessor :battler_name
    attr_accessor :battler_hue
    attr_accessor :edit_map_id
  end

  #===============================================================================
  # RPG::AudioFile
  #===============================================================================
  
  class AudioFile
    def initialize(name = "", volume = 100, pitch = 100)
      @name = name
      @volume = volume
      @pitch = pitch
    end
    attr_accessor :name
    attr_accessor :volume
    attr_accessor :pitch
  end
end

#===============================================================================
# RPG - New Classes/Methods
#===============================================================================

module RPG
  
  #===============================================================================
  # Maps
  #===============================================================================
  
  class Maps
    def initialize
      @data = {}
    end
    
    def [](key)
      unless @data.include?(key)
        return nil unless $data_map_infos.include?(key)
        @data[key] = RPG::load_data(get_map_location(key))
      end
      return @data[key]
    end
    
    def []=(key, value)
      @data[key] = value
    end
    
    def each
      $data_map_infos.keys.sort.each {|key| yield key, self[key]}
    end
    
    def each_key
      $data_map_infos.keys.sort.each {|key| yield key}
    end
    
    def each_value
      $data_map_infos.keys.sort.each {|key| yield self[key]}
    end
        
    def delete(key)
      @data.delete(key)
      File.delete(get_map_location(key))
    end
    
    def get_map_location(key)
      key = key.to_s
      number = (key.size <= 3 ? '0' * (3 - key.size) : '')
      number += key
      return 'Data/Map' + number + '.rxdata'
    end
    
    def save_data
      @data.each do |key, value|
        RPG::save_data(value, get_map_location(key))
      end
    end
  end
  
  #===============================================================================
  # Scripts
  #===============================================================================
  
  class Scripts
    def initialize
      @scripts = RPG::load_data('Data/Scripts.rxdata')
      @data = []
    end
    
    def [](key)
      if @data[key].nil?
        @data[key] = @scripts[key]
        @data[key][2] = Zlib::Inflate.inflate(@data[key][2])
      end
      return @data[key]
    end
    
    def []=(key, value)
      @data[key] = value
    end
    
    def each
      @scripts.each_index {|i| yield self[i]}
    end
    
    def each_index
      @scripts.each_index {|i| yield i}
    end
    
    def each_with_index
      @scripts.each_index {|i| yield self[i], i}
    end
    
    def save_data
      @data.each_with_index do |script, i|
        next if script.nil?
        script[2] = Zlib::Deflate.deflate(script[2])
        @scripts[i] = script
      end
      RPG::save_data(@scripts, 'Data/Scripts.rxdata')
    end
  end    
  
  #===============================================================================
  # Constants
  #===============================================================================
  
  GRAPHICS_EXT = ['.png', '.jpg', '.bmp']
  AUDIO_EXT = ['.ogg', '.aac', '.wma', '.mp3', '.wav', '.it', '.xm', '.mod',
  '.s3m', '.mid', '.midi', '.flac']
  RTP_PATHS = []
  rtps = []
  File.open(ROOT + 'Game.ini', 'rb') do |file|
    file.readlines.each do |line|
      if line['RTP']
        line.gsub!(/RTP[123]=|\r\n/) {''}
        rtps << line if line != ''
      end
    end
  end
  unless rtps.empty?
    ['SOFTWARE\Wow6432Node\Enterbrain\RGSS\RTP',
    'SOFTWARE\Enterbrain\RGSS\RTP'].each do |registry|
      begin
        Win32::Registry::HKEY_LOCAL_MACHINE.open(registry) do |reg|
          rtps.each do |rtp|
            path = reg[rtp].gsub(/\\/) {'/'}
            path += '/' if path[-1, 1] != '/'
            RTP_PATHS << path unless RTP_PATHS.include?(path)
          end
        end
      rescue
      end
    end
  end
  
  module_function
  
  #===============================================================================
  # Location
  #===============================================================================
  
  def location(filename, ext = false)
    filename = filename + (extension(filename)) if ext
    return ROOT + filename if filetest(filename)
    RTP_PATHS.each do |path|
      return path + filename if rtp_filetest(filename)
    end
    return String.new
  end
  
  #===============================================================================
  # Extension
  #===============================================================================
  
  def extension(filename)
    (GRAPHICS_EXT + AUDIO_EXT).each do |extension|
      return extension if filetest(filename + extension, true)
    end
    return String.new
  end
  
  #===============================================================================
  # Load Data
  #===============================================================================
  
  def load_data(filename)
    File.open(ROOT + filename, 'rb') {|file| obj = Marshal.load(file) }
  end
  
  #===============================================================================
  # Save Data
  #===============================================================================
  
  def save_data(obj, filename)
    File.open(ROOT + filename, 'wb') {|file| Marshal.dump(obj, file) }
  end
  
  #===============================================================================
  # Load RPG data
  #===============================================================================
  
  def load_rpg_data
    $data_actors = load_data('Data/Actors.rxdata')
    $data_classes = load_data('Data/Classes.rxdata')
    $data_skills = load_data('Data/Skills.rxdata')
    $data_items = load_data('Data/Items.rxdata')
    $data_weapons = load_data('Data/Weapons.rxdata')
    $data_armors = load_data('Data/Armors.rxdata')
    $data_enemies = load_data('Data/Enemies.rxdata')
    $data_troops = load_data('Data/Troops.rxdata')
    $data_states  = load_data('Data/States.rxdata')
    $data_animations = load_data('Data/Animations.rxdata')
    $data_tilesets = load_data('Data/Tilesets.rxdata')
    $data_common_events = load_data('Data/CommonEvents.rxdata')
    $data_system = load_data('Data/System.rxdata')
    $data_map_infos = load_data('Data/MapInfos.rxdata')
    $data_maps = Maps.new
    $data_scripts = Scripts.new
  end
  
  #===============================================================================
  # Save RPG Data
  #===============================================================================
  
  def save_rpg_data
    save_data($data_actors, 'Data/Actors.rxdata')
    save_data($data_classes, 'Data/Classes.rxdata')
    save_data($data_skills, 'Data/Skills.rxdata')
    save_data($data_items, 'Data/Items.rxdata')
    save_data($data_weapons, 'Data/Weapons.rxdata')
    save_data($data_armors, 'Data/Armors.rxdata')
    save_data($data_enemies, 'Data/Enemies.rxdata')
    save_data($data_troops, 'Data/Troops.rxdata')
    save_data($data_states, 'Data/States.rxdata')
    save_data($data_animations, 'Data/Animations.rxdata')
    save_data($data_tilesets, 'Data/Tilesets.rxdata')
    save_data($data_common_events, 'Data/CommonEvents.rxdata')
    save_data($data_scripts, 'Data/Scripts.rxdata')
    save_data($data_map_infos, 'Data/MapInfos.rxdata')
    $data_maps.save_data
    $data_scripts.save_data
  end
  
  #===============================================================================
  # Filetest
  #===============================================================================
  
  def filetest(filename, rtp = false)
    return true if FileTest.file?(ROOT + filename)
    return true if rtp_filetest(filename) if rtp
    return false
  end
  
  #===============================================================================
  # RTP Filetest
  #===============================================================================
  
  def rtp_filetest(filename)
    return true if RTP_PATHS.any? {|path| FileTest.file?(path + filename)}
    return false
  end
  
  #===============================================================================
  # Rename
  #===============================================================================
  
  def rename(prev, new, swap = false)
    ext = extension(prev)
    prev, new = ROOT + prev + ext, ROOT + new + ext
    if swap && filetest(new)
      File.rename(new, new + 'temp')
      File.rename(prev, new)
      File.rename(new + 'temp', prev)
    else
      File.rename(prev, new)
    end
  end
  
  #===============================================================================
  # Graphic Files
  #===============================================================================
  
  def graphic_files(folder)
    return directory_entries(ROOT + 'Graphics/' + folder, GRAPHICS_EXT)
  end
  
  #===============================================================================
  # Audio Files
  #===============================================================================
  
  def audio_files(folder)
    return directory_entries(ROOT + 'Audio/' + folder, AUDIO_EXT)
  end
  
  #===============================================================================
  # RTP Graphics
  #===============================================================================
  
  def rtp_graphics(folder)
    array = Array.new
    RTP_PATHS.each do |path|
      array |= directory_entries(path + 'Graphics/' + folder, GRAPHICS_EXT)
    end
    return array
  end
  
  #===============================================================================
  # RTP Audio
  #===============================================================================
  
  def rtp_audio(folder)
    array = Array.new
    RTP_PATHS.each do |path|
      array |= directory_entries(path + 'Audio/' + folder, AUDIO_EXT)
    end
    return array
  end
  
  #===============================================================================
  # Directory Entries
  #===============================================================================
  
  def directory_entries(folder, extensions)
    array = Array.new
    Dir.entries(folder).each do |entry|
      extension = File.extname(entry)
      next unless extensions.include?(extension)
      array << File.basename(entry, extension)
    end
    return array
  end
end

RPG::load_rpg_data