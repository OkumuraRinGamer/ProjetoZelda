#===============================================================================
# Missing Filename Finder
#===============================================================================
# Author: Maximusmaxy
# Version 1.0: 29/12/11
#===============================================================================
#
# Introduction:
# Finds references to missing files and saves them in a text document.
#
#===============================================================================

require 'Data/RGSS Library'

#===============================================================================
# Shoes.app
#===============================================================================

Shoes.app(:title => 'Missing Filename Finder', :width => 460, :height => 160,
  :resizable => false) do
  #-----------------------------------------------------------------------------
  # Find
  #-----------------------------------------------------------------------------
  def find
    @para1.replace 'Finding Missing Filenames'
    @button.click {}
    @rate = 0
    @text = []
    @line = ''
    @title = []
    @sub = []
    @cache = {}
    @edit1 = @edit2 = @edit3 = false
    test_database
    test_maps
    test_common_events
    test_troops
    update('Complete')
    if @edit3
      file = File.open("Missing Filename Log.txt",'w')
      @text.each {|line| file.write("#{line}\n")}
      file.close
      @para1.replace 'Missing Filenames Found, Missing Filename Log created'
    else
      @para1.replace 'No Missing Filenames Found'
    end
    @button.remove
    @button = button 'Exit' do exit end
    @button.move(195, 100)
  end
  #-----------------------------------------------------------------------------
  # Test Database
  #-----------------------------------------------------------------------------
  def test_database
    update('Testing Database')
    title('Database')
    @title.shift
    sub('Actors')
    $data_actors.compact.each do |actor|
      @line = "Actor #{actor.id}: #{actor.name}"
      test(actor.character_name,5)
      test(actor.battler_name,4)
    end
    sub('Skills')
    $data_skills.compact.each do |skill|
      @line = "Skill #{skill.id}: #{skill.name}"
      test(skill.menu_se,18)
      test(skill.icon_name,8)
    end
    sub('Items')
    $data_items.compact.each do |item|
      @line = "Item #{item.id}: #{item.name}"
      test(item.menu_se,18)
      test(item.icon_name,8)
    end
    sub('Weapons')
    $data_weapons.compact.each do |weapon|
      @line = "Weapon #{weapon.id}: #{weapon.name}"
      test(weapon.icon_name,8)
    end    
    sub('Armors')
    $data_armors.compact.each do |armor|
      @line = "Armor #{armor.id}: #{armor.name}"
      test(armor.icon_name,8)
    end
    sub('Enemies')
    $data_enemies.compact.each do |enemy|
      @line = "Enemy #{enemy.id}: #{enemy.name}"
      test(enemy.battler_name,4)
    end
    sub('Animations')
    $data_animations.compact.each do |animation|
      @line = "Animation #{animation.id}: #{animation.name}"
      test(animation.animation_name,1)
      animation.timings.each do |timing|
        test(timing.se,18)
      end
    end
    sub('Tilesets')
    $data_tilesets.compact.each do |tileset|
      @line = "Tileset #{tileset.id}: #{tileset.name}"
      test(tileset.tileset_name,11)
      test(tileset.panorama_name,9)
      test(tileset.fog_name,6)
      test(tileset.battleback_name,3)
      tileset.autotile_names.each do |autotile|
        test(autotile,2)
      end
    end
    sub('System')
    @line = 'System'
    test($data_system.windowskin_name,14)
    test($data_system.title_name,12)
    test($data_system.gameover_name,7)
    test($data_system.battle_transition,13)
    test($data_system.title_bgm,15)
    test($data_system.battle_bgm,15)
    test($data_system.battle_end_me,17)
    test($data_system.gameover_me,17)
    test($data_system.cursor_se,18)
    test($data_system.decision_se,18)
    test($data_system.cancel_se,18)
    test($data_system.buzzer_se,18)
    test($data_system.equip_se,18)
    test($data_system.shop_se,18)
    test($data_system.save_se,18)
    test($data_system.load_se,18)
    test($data_system.battle_start_se,18)
    test($data_system.escape_se,18)
    test($data_system.actor_collapse_se,18)
    test($data_system.enemy_collapse_se,18)
  end
  #-----------------------------------------------------------------------------
  # Test Maps
  #-----------------------------------------------------------------------------
  def test_maps
    $data_maps.each do |key, map|
      m = "Map #{key}: #{$data_map_infos[key].name}"
      update("Testing #{m}")
      title(m)
      @line = 'Map'
      test(map.bgm,15) if map.autoplay_bgm
      test(map.bgs,16) if map.autoplay_bgs
      map.events.keys.sort.each do |event_key|
        event = map.events[event_key]
        event.pages.each_with_index do |page, i|
          sub("Event #{event.id}: #{event.name}, Page #{i + 1}")
          @line = 'Page Graphic'
          test(page.graphic.character_name,5)
          if page.move_type == 3
            @line = 'Custom Move Route'
            page.move_route.list.each do |move|
              test_move(move)
            end
          end
          page.list.each_with_index do |command, j|
            @line = "Line #{j + 1}"
            test_command(command)
          end
        end
      end
    end
  end
  #-----------------------------------------------------------------------------
  # Test Common Events
  #-----------------------------------------------------------------------------
  def test_common_events
    update('Testing Common Events')
    title('Common Events')
    $data_common_events.compact.each do |ce|
      sub("Common Event #{ce.id}: #{ce.name}")
      ce.list.each_with_index do |command,i|
        @line = "Line #{i + 1}"
        test_command(command)
      end
    end
  end
  #-----------------------------------------------------------------------------
  # Test Troops
  #-----------------------------------------------------------------------------
  def test_troops
    update('Testing Troops')
    title('troops')
    $data_troops.compact.each do |troop|
      troop.pages.each_with_index do |page, i|
        sub("Troop #{troop.id}: #{troop.name}, Page #{i + 1}")
        page.list.each_with_index do |command, j|
          @line = "Line #{j + 1}"
          test_command(command)
        end
      end
    end
  end
  #-----------------------------------------------------------------------------
  # Test Command
  #-----------------------------------------------------------------------------
  def test_command(command)
    case command.code
    when 131
      test(command.parameters[0],14)
    when 132
      test(command.parameters[0],15)
    when 133
      test(command.parameters[0],17)
    when 204
      case command.parameters[0]
      when 0
        test(command.parameters[1],9)
      when 1
        test(command.parameters[1],6)
      when 2
        test(command.parameters[1],3)
      end
    when 209
      command.parameters[1].list.each do |move|
        test_move(move)
      end
    when 222
      test(command.parameters[0],13)
    when 231
      test(command.parameters[1],10)
    when 241
      test(command.parameters[0],15)
    when 245
      test(command.parameters[0],16)
    when 249
      test(command.parameters[0],17)
    when 250
      test(command.parameters[0],18)
    when 322
      test(command.parameters[1],5)
      test(command.parameters[3],4)
    end
  end
  #-----------------------------------------------------------------------------
  # Test Move
  #-----------------------------------------------------------------------------
  def test_move(move)
    if move.code == 41
      test(move.parameters[0],5)
    elsif move.code == 44
      test(move.parameters[0],18)
    end
  end
  #-----------------------------------------------------------------------------
  # Title
  #-----------------------------------------------------------------------------
  def title(text)
    @edit1 = false
    @title = '', '#' + '=' * 50, '# ' + text, '#' + '=' * 50, ''
  end
  #-----------------------------------------------------------------------------
  # Subtitle
  #-----------------------------------------------------------------------------
  def sub(text)
    @edit2 = false
    @sub = '', '#' + '-' * 50, '# ' + text, '#' + '-' * 50, ''
  end
  #-----------------------------------------------------------------------------
  # Test
  #-----------------------------------------------------------------------------
  def test(file,type)
    file = file.name if type > 14
    return if file == ''
    unless filetest(file,type)
      @text.push(*@title) unless @edit1
      @text.push(*@sub) unless @edit2
      @edit1 = @edit2 = @edit3 = true
      @text.push "#{@line}, #{folder(type,false)} '#{file}'"
    end
  end
  #-----------------------------------------------------------------------------
  # Filetest
  #-----------------------------------------------------------------------------
  def filetest(file,type)
    if type <= 14
      folder = 'Graphics'
      extensions = RPG::GRAPHICS_EXT
    else
      folder = 'Audio'
      extensions = RPG::AUDIO_EXT
    end
    name = "#{folder}/#{folder(type)}/#{file}"
    return true if RPG::filetest(name, true)
    extensions.each do |ext| 
      return true if RPG::filetest("#{name}#{ext}", true)
    end
    return false
  end
  #-----------------------------------------------------------------------------
  # Folder
  #-----------------------------------------------------------------------------
  def folder(type,s = true)
    case type
    when 1 then text = 'Animation'
    when 2 then text = 'Autotile'
    when 3 then text = 'Battleback'
    when 4 then text = 'Battler'
    when 5 then text = 'Character'
    when 6 then text = 'Fog'
    when 7 then text = 'Gameover'
    when 8 then text = 'Icon'
    when 9 then text = 'Panorama'
    when 10 then text = 'Picture'
    when 11 then text = 'Tileset'
    when 12 then text = 'Title'
    when 13 then text = 'Transition'
    when 14 then text = 'Windowskin'
    when 15 then text = 'BGM'
    when 16 then text = 'BGS'
    when 17 then text = 'ME'
    when 18 then text = 'SE'
    end
    text += 's' if s && type <= 14
    return text
  end
  #-----------------------------------------------------------------------------
  # Update
  #-----------------------------------------------------------------------------
  def update(text)
    @rate += 1
    @progress.fraction = @rate.to_f / ($data_map_infos.size + 4).to_f
    @para2.replace(text)
  end
  #-----------------------------------------------------------------------------
  # Stack
  #-----------------------------------------------------------------------------
  background rgb(236,233,216)
  stack do
    @para1 = para 'Missing Filename Finder', :align => 'center'
    @para2 = para '', :align => 'center'
    @progress = progress
    @progress.move(135, 70)
    @button = button 'start' do find end
    @button.move(190, 100)
  end
end
