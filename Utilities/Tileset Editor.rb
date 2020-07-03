#===============================================================================
# Tileset Editor
#===============================================================================
# Author: Maximusmaxy
# Version 1.0: 14/4/2012
# Thanks to:
# Shoooes! - GUI for the editor
#===============================================================================
#
# Introduction:
# Emulates RMXP's default tileset editor without the limits
#
#===============================================================================

require 'Data/RGSS Library'

ID_REGEXP = /^(\d*)\D/
SQUARE = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,24,25,26,27,28,29,30,31,32,38,39,40,41,44]

#===============================================================================
# Tileset Viewer
#===============================================================================

class Tileset_Viewer
  attr_reader :app
  attr_reader :stack
  #-----------------------------------------------------------------------------
  # Initialize
  #-----------------------------------------------------------------------------
  def initialize(app)
    @app = app
    @app.stack(:left => 278, :top => 18, :width => 276, :height => 516) do 
      @app.border(@app.black, :strokewidth => 2)
      @stack = @app.stack(:left => 2, :top => 2, :width => 272,:height => 512, :scroll => true)
    end
    @app.animate(1) {|frame| update }
    @app.click {|button, x, y| update_click(button, x, y) }
    @top = 0
    @cells = Array.new
    refresh
  end
  #-----------------------------------------------------------------------------
  # Edit Type
  #-----------------------------------------------------------------------------
  def edit_type
    @app.edit_radio.each_with_index {|radio, i| return i if radio.checked? }
    return 0
  end
  #-----------------------------------------------------------------------------
  # Refresh
  #-----------------------------------------------------------------------------
  def refresh
    @stack.clear do
      @app.fill @app.white
      @app.nostroke
      location = RPG::location('Graphics/Tilesets/' + @app.tileset.tileset_name, true)
      if location == ''
        width, height = 256, 32
        @app.rect(0, 0, width, height)
      else
        width, height = *@app.imagesize(location)
        height += 32
        @app.rect(0, 0, width, height)
        @app.image(location, :displace_top => 32)
        @app.tileset.autotile_names.each_with_index do |name, i|
          next if name == ''
          location = RPG::location('Graphics/Autotiles/' + name, true)
          next if location == ''
          @app.fill(location)
          @app.rect(32 + i * 32, 0, 32, 32)
        end
      end
      @app.nofill
      @app.stroke @app.rgb(128, 128, 128, 200)
      @app.strokewidth(2)
      @app.shape do
        8.times {|i| @app.line(i * 32 - 1, -1, i * 32 - 1, height - 1) }
        (height / 32 + 1).times {|i| @app.line(-1, i * 32 - 1, 255, i * 32 - 1) }
      end
    end
    @stack.scroll_top = 0
    @top = 0
    setup_cells
  end
  #-----------------------------------------------------------------------------
  # Setup Cells
  #-----------------------------------------------------------------------------
  def setup_cells
    @cells.clear
    type = edit_type
    (@top * 8).upto([135 + @top * 8, @app.tileset.passages.xsize - 377].min) do |i|
      @cells << Tileset_Cell.new(self, i, type)
    end
  end
  #-----------------------------------------------------------------------------
  # Refresh Cells
  #-----------------------------------------------------------------------------
  def refresh_cells
    type = edit_type
    @cells.each {|cell| cell.type = type }
  end
  #-----------------------------------------------------------------------------
  # Refresh Data
  #-----------------------------------------------------------------------------
  def refresh_data
    @cells.each {|cell| cell.refresh_data }
  end
  #-----------------------------------------------------------------------------
  # Update
  #-----------------------------------------------------------------------------
  def update
    top = @stack.scroll_top / 32
    return if @top == top
    diff = (top - @top) * 8
    @top = top
    if diff.abs >= 136
      @cells.each {|cell| cell.remove }
      return setup_cells
    end
    if diff > 0
      diff.times do
        @cells[0].remove
        @cells.push(@cells.shift)
        @cells[-1].index += 136
        @cells[-1].refresh
      end
    else
      (-diff).times do
        @cells[-1].remove
        @cells.unshift(@cells.pop)
        @cells[0].index -= 136
        @cells[0].refresh
      end
    end
  end
  #-----------------------------------------------------------------------------
  # Update Click
  #-----------------------------------------------------------------------------
  def update_click(button, x, y)
    return unless x.between?(280, 280 + 256)
    return unless y.between?(20, 20 + @stack.height)
    sx = (x - 280) / 32
    sy = (y - 20 + @stack.scroll_top) / 32
    index = sx + sy * 8
    case edit_type
    when 0 #Passage
      if index < 8
        square = false
        value = @app.tileset.passages[index * 48]
        if value & 0x10 == 0x10
          value -= 0x10
          value |= 0x0f
        elsif value & 0x0f == 0x0f
          value -= 0x0f
        else
          value |= 0x10
          square = true
        end
        (index * 48).upto((index + 1) * 48 - 1) do |i|
          if square && SQUARE.include?(i - index * 48)
            @app.tileset.passages[i] = value | 0x0f
          else
            @app.tileset.passages[i] = value
          end
        end
      else
        value = @app.tileset.passages[376 + index]
        if value & 0x0f == 0x0f
          value -= 0x0f
        else
          value |= 0x0f
        end
        @app.tileset.passages[376 + index] = value
      end
    when 1 #Passage4
      cx = (x - 280) % 32
      cy = (y - 20 + @stack.scroll_top) % 32
      if cx < cy
        if 32 - cx < cy
          bit = 0x01
        else
          bit = 0x02
        end
      else
        if 32 - cx < cy
          bit = 0x04
        else
          bit = 0x08
        end
      end
      if index < 8
        value = @app.tileset.passages[index * 48]
        square = (value & 0x10 == 0x10)
        if value & bit == bit
          value -= bit
        else
          value |= bit
        end
        (index * 48).upto((index + 1) * 48 - 1) do |i|
          next if square && !SQUARE.include?(i - index * 48)
          @app.tileset.passages[i] = value
        end
      else
        value = @app.tileset.passages[376 + index]
        if value & bit == bit
          value -= bit
        else
          value |= bit
        end
        @app.tileset.passages[376 + index] = value
      end
    when 2 #Priority
      inc = (button == 1 ? 1 : button == 2 ? -1 : 0)
      if index < 8
        value = @app.tileset.priorities[index * 48]
        value = (value + inc) % 6
        (index * 48).upto((index + 1) * 48 - 1) do |i|
          @app.tileset.priorities[i] = value
        end
      else
        value = @app.tileset.priorities[376 + index]
        value = (value + inc) % 6
        @app.tileset.priorities[376 + index] = value
      end
    when 3 #Bush
      if index < 8
        value = @app.tileset.passages[index * 48]
        (value & 0x40 == 0x40) ? value -= 0x40 : value |= 0x40
        (index * 48).upto((index + 1) * 48 - 1) do |i|
          @app.tileset.passages[i] = value
        end
      else
        value = @app.tileset.passages[376 + index]
        (value & 0x40 == 0x40) ? value -= 0x40 : value |= 0x40
        @app.tileset.passages[376 + index] = value
      end
    when 4 #Counter
      if index < 8
        value = @app.tileset.passages[index * 48]
        (value & 0x80 == 0x80) ? value -= 0x80 : value |= 0x80
        (index * 48).upto((index + 1) * 48 - 1) do |i|
          @app.tileset.passages[i] = value
        end
      else
        value = @app.tileset.passages[376 + index]
        (value & 0x80 == 0x80) ? value -= 0x80 : value |= 0x80
        @app.tileset.passages[376 + index] = value
      end
    when 5 #Terrain
      string = ask('Enter the terrain tag.')
      value = string.to_i
      if !string.nil? &&
        (!value.between?(-32768, 32767) || (value == 0 && string != '0'))
        return alert('Invalid Terrain Tag')
      end
      if index < 8
        (index * 48).upto((index + 1) * 48 - 1) do |i|
          @app.tileset.terrain_tags[i] = value
        end
      else
        @app.tileset.terrain_tags[376 + index] = value
      end
    end
    @cells.each {|cell| cell.refresh if cell.index == index }
  end
end

#===============================================================================
# Tileset Cell
#===============================================================================

class Tileset_Cell
  #-----------------------------------------------------------------------------
  # Initialize
  #-----------------------------------------------------------------------------
  def initialize(viewer, index, type)
    @viewer = viewer
    @app = @viewer.app
    @index = index
    @type = type
    self.index = index
    refresh
  end
  #-----------------------------------------------------------------------------
  # Type=
  #-----------------------------------------------------------------------------
  def type=(type)
    return if @type == type
    @type = type
    refresh
  end
  #-----------------------------------------------------------------------------
  # Index
  #-----------------------------------------------------------------------------
  def index
    return @base_index
  end
  #-----------------------------------------------------------------------------
  # Index=
  #-----------------------------------------------------------------------------
  def index=(value)
    @base_index = value
    @left = @base_index % 8 * 32
    @top = @base_index / 8 * 32
    if @base_index < 8
      @index = @base_index * 48
    else
      @index = 376 + @base_index
    end
  end
  #-----------------------------------------------------------------------------
  # Remove
  #-----------------------------------------------------------------------------
  def remove
    return if @image.nil?
    if @image.is_a?(Array)
      @image.each {|image| image.remove }
    else
      @image.remove
    end
    @image = nil
  end
  #-----------------------------------------------------------------------------
  # Draw Number
  #-----------------------------------------------------------------------------
  def draw_number
    widths = Array.new
    paths = Array.new
    total_width = 0
    @data.to_s.scan(/./) do |s|
      path = "Data/Number - #{s}.png"
      paths << path
      widths << @app.imagesize(path)[0]
      total_width += widths[-1]
    end
    left = @left + 16 - total_width / 2
    total_width = 0
    @image = Array.new
    paths.each_with_index do |path, i|
      @image << @app.image(path, :left => left + total_width, :top => @top)
      total_width += widths[i]
    end
  end
  #-----------------------------------------------------------------------------
  # Refresh
  #-----------------------------------------------------------------------------
  def refresh
    self.remove
    @viewer.stack.append do
      case @type
      when 0 #Passage
        @data = @app.tileset.passages[@index]
        if @data & 0x10 == 0x10
          @image = @app.image('Data/Tileset - Square.png', :left => @left, :top => @top)
        elsif @data & 0x0f == 0x0f
          @image = @app.image('Data/Tileset - Cross.png', :left => @left, :top => @top)
        else
          @image = @app.image('Data/Tileset - Circle.png', :left => @left, :top => @top)
        end
      when 1 #Passage4
        @data = @app.tileset.passages[@index]
        @image = Array.new
        if @data & 0x01 == 0x01
          @image << @app.image('Data/Tileset - Impassable Down.png', :left => @left, :top => @top)
        else
          @image << @app.image('Data/Tileset - Down.png', :left => @left, :top => @top)
        end
        if @data & 0x02 == 0x02
          @image << @app.image('Data/Tileset - Impassable Left.png', :left => @left, :top => @top)
        else
          @image << @app.image('Data/Tileset - Left.png', :left => @left, :top => @top)
        end
        if @data & 0x04 == 0x04
          @image << @app.image('Data/Tileset - Impassable Right.png', :left => @left, :top => @top)
        else
          @image << @app.image('Data/Tileset - Right.png', :left => @left, :top => @top)
        end
        if @data & 0x08 == 0x08
          @image << @app.image('Data/Tileset - Impassable Up.png', :left => @left, :top => @top)
        else
          @image << @app.image('Data/Tileset - Up.png', :left => @left, :top => @top)
        end
      when 2 #Priority
        @data = @app.tileset.priorities[@index]
        if @data == 0
          @image = @app.image('Data/Tileset - Blank.png', :left => @left, :top => @top)
        else
          draw_number
        end
      when 3 #Bush
        @data = @app.tileset.passages[@index]
        if @data & 0x40 == 0x40
          @image = @app.image('Data/Tileset - Bush.png', :left => @left, :top => @top)
        else
          @image = @app.image('Data/Tileset - Blank.png', :left => @left, :top => @top)
        end
      when 4 #Counter
        @data = @app.tileset.passages[@index]
        if @data & 0x80 == 0x80
          @image = @app.image('Data/Tileset - Counter.png', :left => @left, :top => @top)
        else
          @image = @app.image('Data/Tileset - Blank.png', :left => @left, :top => @top)
        end
      when 5 #Terrain Tag
        @data = @app.tileset.terrain_tags[@index]
        draw_number
      end
    end
  end
  #-----------------------------------------------------------------------------
  # Refresh Data
  #-----------------------------------------------------------------------------
  def refresh_data
    case @type
    when 0, 1, 3, 4 then data = @app.tileset.passages[@index]
    when 2 then data = @app.tileset.priorities[@index]
    when 5 then data = @app.tileset.terrain_tags[@index]
    end
    return if @data == data
    refresh
  end
end

#===============================================================================
# Shoes.app
#===============================================================================

Shoes.app(:title => 'Tileset Editor', :width => 800, :height => 600,
  :resize => false) do
  #===============================================================================
  # Tileset
  #===============================================================================
  def tileset
    return $data_tilesets[@tileset_id]
  end
  #===============================================================================
  # Edit Radio
  #===============================================================================
  def edit_radio
    return @edit_radio
  end
  #===============================================================================
  # Refresh Tileset List
  #===============================================================================
  def refresh_tileset_list
    list = Array.new
    $data_tilesets.each_with_index do |data, i|
      next if data.nil?
      list << "#{i}: #{data.name}"
    end
    @tileset_list.items = list
    @tileset_list.choose("#{tileset.id}: #{tileset.name}")
  end
  #===============================================================================
  # Refresh Tileset Info
  #===============================================================================
  def refresh_tileset_info
    refresh_tileset_list
    text = (tileset.name == '' ? '(None)' : tileset.name)
    @tileset_name.text = text
    text = (tileset.tileset_name == '' ? '(None)' : tileset.tileset_name)
    @tileset_graphic.text = text
    @autotiles.each_with_index do |tile, i|
      text = (tileset.autotile_names[i] == '' ? '(None)' : tileset.autotile_names[i])
      tile.text = text
    end
    text = (tileset.panorama_name == '' ? '(None)' : tileset.panorama_name)
    @panorama.text = text
    text = (tileset.fog_name == '' ? '(None)' : tileset.fog_name)
    @fog.text = text
    text = (tileset.battleback_name == '' ? '(None)' : tileset.battleback_name)
    @battleback.text = text
  end
  #===============================================================================
  # Choose Graphic
  #===============================================================================
  def choose_graphic(folder, element, index = 0)
    window(:title => folder, :width => 600, :height => 500) do
      tileset = owner.tileset
      #Background Color
      background rgb(236,233,216)
      #Left Column
      stack(:margin_left => 40, :margin_top => 10) do
        #Graphic List
        para 'Graphic'
        list = Array.new(1,'(None)')
        list += RPG::graphic_files(folder).sort
        list += RPG::rtp_graphics(folder).sort
        text = (element.text == '' ? '(None)' : element.text)
        @element_list = list_box(:items => list, :choose => text) do |line|
          @element_picture.clear do
            fill white
            location = RPG::location("Graphics/#{folder}/#{line.text}", true)
            if location == '' || line.text == '(None)'
              rect(0, 0, 256, 400)
            else
              size = imagesize(location)
              rect(0, 0, size[0] - 2, size[1] - 2)
              image(location)
            end
          end
        end
        #Hue
        if ['Panoramas', 'Fogs'].include?(folder)
          para 'Hue'
          case folder
          when 'Panoramas' then text = tileset.panorama_hue
          when 'Fogs' then text = tileset.fog_hue
          end
          @element_hue = edit_line(:text => text)
        end
        #Fogs
        if folder == 'Fogs'
          #Opacity
          para 'Opacity'
          @element_opacity = edit_line(:text => tileset.fog_opacity)
          #Blending
          para 'Blending'
          blend = case tileset.fog_blend_type
          when 0 then 'Normal'
          when 1 then 'Add'
          when 2 then 'Sub'
          end
          @element_blending = list_box(:items => ['Normal', 'Add', 'Sub'], :choose => blend)
          #Zoom
          para 'Zoom'
          @element_zoom = edit_line(:text => tileset.fog_zoom)
          #SX
          para 'SX'
          @element_sx = edit_line(:text => tileset.fog_sx)
          #SY
          para 'SY'
          @element_sy = edit_line(:text => tileset.fog_sy) 
        end
      end
      #Picture Viewer
      @element_picture = stack(:left => 270, :top => 10, :width => 276,
      :height => 400, :scroll => true) do
        fill white
        text = (element.text == '' ? '(None)' : element.text)
        location = RPG::location("Graphics/#{folder}/#{text}", true)
        if location == '' || @element_list.text == '(None)'
          rect(0, 0, 256, 400)
        else
          size = imagesize(location)
          rect(0, 0, size[0] - 2, size[1] - 2)
          image(location)
        end
      end
      flow(:left => 450, :top => 450) do
        #Cancel
        button('Cancel') { close }
        #Ok
        button('Ok') do
          name = @element_list.text
          element.text = name
          case folder
          when 'Tilesets'
            tileset.tileset_name = name
            location = RPG::location('Graphics/Tilesets/' + name, true)
            if name == '(None)' || location == ''
              tileset.passages.xsize = 384
              tileset.priorities.xsize = 384
              tileset.priorities.xsize = 384
            else
              width, height = *imagesize(location)
              size = height / 32 * 8 + 384
              tileset.passages.xsize = size
              tileset.priorities.xsize = size
              tileset.terrain_tags.xsize = size
            end
            owner.tileset_viewer.refresh
          when 'Autotiles'
            tileset.autotile_names[index] = name
            owner.tileset_viewer.refresh
          when 'Panoramas'
            tileset.panorama_name = name
            tileset.panorama_hue = [[@element_hue.text.to_i, 359].min, 0].max
          when 'Fogs'
            tileset.fog_name = @element_list.text
            tileset.fog_hue = [[@element_hue.text.to_i, 359].min, 0].max
            tileset.fog_opacity = [[@element_opacity.text.to_i, 255].min, 0].max
            case @element_blending
            when 'Normal' then tileset.fog_blend_type = 0
            when 'Add' then tileset.fog_blend_type = 1
            when 'Sub' then tileset.fog_blend_type = 2
            end
            tileset.fog_zoom = [[@element_zoom.text.to_i, 800].min, 100].max
            tileset.fog_sx = [[@element_sx.text.to_i, 256].min, -256].max
            tileset.fog_sy = [[@element_sy.text.to_i, 256].min, -256].max
          when 'Battlebacks' then owner.tileset.battleback_name = name
          end
          close
        end
      end
    end
  end
  #===============================================================================
  # Elements
  #===============================================================================
  #Initialize the tileset ID
  @tileset_id = 1
  #Background Color
  background rgb(236,233,216)
  #Left Column
  stack(:margin_left => 40, :margin_top => 10) do
    #Tileset List
    para 'Tileset'
    @tileset_list = list_box(:choose => "1: #{tileset.name}") do |list|
      list.text.gsub(ID_REGEXP) do
        if $1.to_s != ''
          @tileset_id = $1.to_i
          @tileset_name.text = tileset.name
          refresh_tileset_info
          @tileset_viewer.refresh
        end
      end
    end
    #Tileset Name
    para 'Name'
    @tileset_name = edit_line do
      tileset.name = @tileset_name.text
      refresh_tileset_list
    end
    #Tileset Graphic
    para 'Tileset Graphic'
    flow do
      @tileset_graphic = edit_line(:width => 130)
      button('Search') { choose_graphic('Tilesets', @tileset_graphic) }
    end
    #Autotile Graphics
    para 'Autotile Graphics'
    @autotiles = []
    7.times do |i|
      flow do
        @autotiles[i] = edit_line(:width => 130)
        button('Search') { choose_graphic('Autotiles', @autotiles[i], i) }
      end
    end
    #Panorama Graphic
    para 'Panorama Graphic'
    flow do
      @panorama = edit_line(:width => 130)
      button('Search') { choose_graphic('Panoramas', @panorama) }
    end
    #Fog Graphic
    para 'Fog Graphic'
    flow do
      @fog = edit_line(:width => 130)
      button('Search') { choose_graphic('Fogs', @fog) }
    end
    #Battleback Graphic
    para 'Battleback Graphic'
    flow do
      @battleback = edit_line(:width => 130)
      button('Search') { choose_graphic('Battlebacks', @battleback) }
    end
  end
  refresh_tileset_info
  #Right Column
  stack(:left => 560, :top => 15) do
    #Maximum
    para 'Maximum'
    flow do
      @maximum = edit_line(:text => ($data_tilesets.size - 1).to_s, :width => 100)
      button('Change') do
        max = @maximum.text.to_i
        if (max + 1 >= $data_tilesets.size) ||
           confirm('Tileset Data will be lost. Are you sure you want to continue?')
          if max < 1000 || confirm('Maximum is over 999. Are you sure you want to continue?')
            if max > $data_tilesets.size - 1
              $data_tilesets.size.upto(max) do |i|
                $data_tilesets[i] = RPG::Tileset.new
                $data_tilesets[i].id = i
              end
            else
              $data_tilesets = $data_tilesets[0, max + 1]
            end
            refresh_tileset_list
          end
        end
      end
    end
    @edit_radio = []
    para 'Edit Mode'
    #Passage
    flow do
      @edit_radio[0] = radio(:type, :checked => true) { @tileset_viewer.refresh_cells }
      para 'Passage'
    end
    #Passage (4 dir)
    flow do
      @edit_radio[1] = radio(:type) { @tileset_viewer.refresh_cells }
      para 'Passage (4 dir)'
    end
    #Priority
    flow do
      @edit_radio[2] = radio(:type) { @tileset_viewer.refresh_cells }
      para 'Priority'
    end
    #Bush flag
    flow do
      @edit_radio[3] = radio(:type) { @tileset_viewer.refresh_cells }
      para 'Bush Flag'
    end
    #Counter flag
    flow do
      @edit_radio[4] = radio(:type) { @tileset_viewer.refresh_cells }
      para 'Counter Flag'
    end
    #Terrain tag
    flow do
      @edit_radio[5] = radio(:type) { @tileset_viewer.refresh_cells }
      para 'Terrain Tag'
    end
    para 'Reset'
    #Reset Passage
    button('Reset Passages') do
      if confirm('This will reset all passage data. Are you sure you want to continue?')
        tileset.passages.xsize.times do |i|
          value = tileset.passages[i]
          value -= 0x01 if value & 0x01 == 0x01
          value -= 0x02 if value & 0x02 == 0x02
          value -= 0x04 if value & 0x04 == 0x04
          value -= 0x08 if value & 0x08 == 0x08
          value -= 0x10 if value & 0x10 == 0x10
          tileset.passages[i] = value
        end
        @tileset_viewer.refresh_data if [0,1].any? {|i| @edit_radio[i].checked? }
      end
    end
    #Reset Priority
    button('Reset Prioritys') do
      if confirm('This will reset all priority data. Are you sure you want to continue?')
        tileset.priorities.xsize.times do |i|
          tileset.priorities[i] = 0
        end
        tileset.priorities[0] = 5
        @tileset_viewer.refresh_data if @edit_radio[2].checked?
      end
    end
    #Reset Bush
    button('Reset Bush Flags') do
      if confirm('This will reset all bush flags. Are you sure you want to continue?')
        tileset.passages.xsize.times do |i|
          value = tileset.passages[i]
          value -= 0x40 if value & 0x40 == 0x40
          tileset.passages[i] = value
        end
        @tileset_viewer.refresh_data if @edit_radio[3].checked?
      end
    end
    #Reset Counter
    button('Reset Counter Flags') do
      if confirm('This will reset all counter flags. Are you sure you want to continue?')
        tileset.passages.xsize.times do |i|
          value = tileset.passages[i]
          value -= 0x80 if value & 0x80 == 0x80
          tileset.passages[i] = value
        end
        @tileset_viewer.refresh_data if @edit_radio[4].checked?
      end
    end
    #Reset Terrain Tag
    button('Reset Terrain Tags') do
      if confirm('This will reset all terrain tags. Are you sure you want to continue?')
        tileset.terrain_tags.xsize.times do |i|
          tileset.terrain_tags[i] = 0
        end
        @tileset_viewer.refresh_data if @edit_radio[5].checked?
      end
    end
    #Save
    para 'Save'
    button('Save') do
      if confirm('Are you sure you want to save? '+
        'Make sure the RMXP Editor is closed before saving.')
        RPG::save_data($data_tilesets, 'Data/Tilesets.rxdata')
      end
    end
  end
  #Tileset Viewer
  @tileset_viewer = Tileset_Viewer.new(self)
end