#===============================================================================
# Filename/Database Swap
#===============================================================================
# Author: Maximusmaxy
# Version 1.0: 28/12/11
#===============================================================================
#
# Note: Make Sure the RMXP Editor is closed when using this application
#
# Introduction:
# Ever wanted to change a filename, or simply move a database name without
# having to go through the  grueling task of going through every event and 
# changing it's information. This script allows you to change filenames and
# adjust database positions with a simple script call. You can also adjust 
# switch/variable/map ID's.
#
#===============================================================================

require 'Data/RGSS Library'

FILE_REGEXP = /\/([^\/]*)\/([^\/]*)\/([^\/]*)$/
INVALID_REGEXP = /\\|\/|\:|\*|\?|\"|\<|\>|\|/
DATA_REGEXP = /^(\d*)\D/

Shoes.app(:title => 'Filename Database Swap', :width => 560, :height => 300,
  :resizable => false) do
  #-----------------------------------------------------------------------------
  # Initialize
  #-----------------------------------------------------------------------------
  @type = 0
  @prev = ''
  @new = ''
  #-----------------------------------------------------------------------------
  # Swap
  #-----------------------------------------------------------------------------
  def swap
    @change = @change_check.checked?
    @rate = 0
    change_database
    change_maps_events
    change_troops
    change_common_events
    @type <= 18 ? change_file : change_data if @change
    update('Saving')
    RPG::save_rpg_data
    update_database_list
    update('Complete')
  end
  #-----------------------------------------------------------------------------
  # Error Check
  #-----------------------------------------------------------------------------
  def error_check
    unless @type.between?(1,34)
      alert 'Error, Swap Type is invalid' 
      return false
    end
    @prev, @new = @prev_line.text, @new_line.text
    if @prev == @new
      alert 'Error, the previous and new filename/id\'s are the same'
      return false
    end
    if @type <= 18
      if @new == ''
        alert 'Error, the new filename is empty'
        return false
      end
      if @new[INVALID_REGEXP]
        alert 'Error, the new filename includes an invalid character \ / : * ? " < > |'
        
        return false
      end
      path = "#{folder}/#{string}/#{@new}"
      path += RPG::extension(path)
      if !@overwrite_check.checked? && RPG::filetest(path)
        alert 'Error, the new filename already exists and overwrite is disabled'
        return false
      end
      if @prev == ''
        alert 'Error, the previous filename is empty'
        return false
      end
      if @prev[INVALID_REGEXP]
        alert 'Error, the previous filename includes an invalid character \ / : * ? " < > |'
        return false
      end
      path = "#{folder}/#{string}/#{@prev}"
      path += RPG::extension(path)
      unless RPG::filetest(path)
        alert 'Error, the previous filename could not be found'
        return false
      end
    else
      @prev, @new = @prev.to_i, @new.to_i
      if @prev < 1
        alert "Error, '#{@prev}' is an invalid ID"
        return false
      end
      if @new < 1
        alert "Error, '#{@new}' is an invalid ID"
        return false
      end
      if @type == 34
        if $data_maps[@prev].nil?
          alert "Error, Map #{@prev} could not be found"
          return false
        end
      elsif data[@prev].nil?
        alert "Error, #{string} #{@prev} could not be found"
        return false
      end      
    end
    return confirm("Make sure the RMXP Editor is closed before swapping. Are you ready to continue?")
  end
  #-----------------------------------------------------------------------------
  # Location Check
  #-----------------------------------------------------------------------------
  def location_check(text, type_text, folder_text)
    if !['Graphics','Audio'].include?(folder_text) ||
       type(type_text) == 0 ||
       !RPG::filetest("#{folder_text}/#{type_text}/#{text}")
      alert 'Error, File location is invalid'
      return false
    end
    return true    
  end
  #-----------------------------------------------------------------------------
  # Start Check
  #-----------------------------------------------------------------------------
  def start_check
    return [0.0, 1.0].include?(@progress.fraction)
  end
  #-----------------------------------------------------------------------------
  # Change File
  #-----------------------------------------------------------------------------
  def change_file
    update('Changing Filename')
    prev = "#{folder}/#{string}/#{@prev}"
    new = "#{folder}/#{string}/#{@new}"
    RPG::rename(prev, new, @change)
  end
  #-----------------------------------------------------------------------------
  # Change Data
  #-----------------------------------------------------------------------------
  def change_data
    update('Swapping Database ID')
    if @type == 34
      if $data_maps[@new].nil?
        $data_maps[@new] = $data_maps[@prev]
        $data_maps.delete(@prev)
      else
        $data_maps[@prev], $data_maps[@new] = $data_maps[@new], $data_maps[@prev]
      end
    elsif @new > data.size - 1
      (data.size..@new).each do |i|
        data[i] = object
        data[i].id = i if @type < 31
      end
    end
    data[@new], data[@prev] = data[@prev], data[@new]
    data.delete(@prev) if @type == 34 && data[@prev].nil?
    data[@prev].id, data[@new].id = @new, @prev if @type < 31
  end
  #-----------------------------------------------------------------------------
  # Change Maps/Events
  #-----------------------------------------------------------------------------
  def change_maps_events
    $data_maps.each do |key, map|
      update("Updating Map #{key}: #{$data_map_infos[key].name}")
      case @type
      when 15 then map.bgm = audio(map.bgm) if map.autoplay_bgm
      when 16 then map.bgs = audio(map.bgs) if map.autoplay_bgs
      when 26 then map.encounter_list.each {|id| id = change(id) }
      when 29 then map.tileset_id = change(map.tileset_id)
      end
      map.events.each_value do |event|
        event.pages.each do |page|
          if page.move_type == 3
            page.move_route.list.each {|move| move = move(move) }
          end
          case @type
          when 5
            page.graphic.character_name = change(page.graphic.character_name)
            
          when 32
            if page.condition.switch1_valid
              page.condition.switch1_id = change(page.condition.switch1_id) 
               
            end
            if page.condition.switch2_valid
              page.condition.switch2_id = change(page.condition.switch2_id)
            end
          when 33
            if page.condition.variable_valid
              page.condition.variable_id = change(page.condition.variable_id)
            end
          end
          page.list.each {|command| command = command(command) }
        end
      end
    end
  end
  #-----------------------------------------------------------------------------
  # Change Common Events
  #-----------------------------------------------------------------------------
  def change_common_events
    update("Updating Common Events")
    $data_common_events.each do |ce|
      next if ce.nil?
      ce.list.each {|command| command = command(command) }
    end
  end
  #-----------------------------------------------------------------------------
  # Change Troops
  #----------------------------------------------------------------------------- 
  def change_troops
    update("Updating Troops")
    $data_troops.each do |troop|
      next if troop.nil?
      troop.pages.each {|page| page.list.each {|command| command = command(command)}}
    end
  end
  #-----------------------------------------------------------------------------
  # Command
  #-----------------------------------------------------------------------------
  def command(command)
    command_array(command).each do |c|
      if command.code == c[0]
        case command.parameters[c[1]]
        when Numeric
          command.parameters[c[1]] = change(command.parameters[c[1]])
        when RPG::AudioFile
          command.parameters[c[1]] = audio(command.parameters[c[1]])
        when RPG::MoveRoute
          command.parameters[c[1]].list.each {|move| move = move(move) }
        when RPG::MoveCommand
          command.parameters[c[1]] = move(command.parameters[c[1]])
        end
      end
    end
    return command
  end
  #-----------------------------------------------------------------------------
  # Move
  #-----------------------------------------------------------------------------
  def move(command)
    case @type
    when 5 
      if command.code == 41
        command.parameters[0] = change(command.parameters[0])
      end
    when 18
      if command.code == 44
        command.parameters[0] = audio(command.parameters[0])
      end
    when 32
      if [27,28].include?(command.code)
        command.parameters[0] = change(command.parameters[0])
      end
    end
    return command
  end
  #-----------------------------------------------------------------------------
  # Command Array
  #-----------------------------------------------------------------------------
  def command_array(command)
    check = []
    return check if [205,223,224,234].include?(command.code)
    case @type
    when 3 then check.push [204,1] if command.parameters[0] == 2
    when 4 then check.push [322,3]
    when 5 then check.push [322,1], [209,1]
    when 6 then check.push [204,1] if command.parameters[0] == 1
    when 9 then check.push [204,1] if command.parameters[0] == 0
    when 10 then check.push [231,1]
    when 13 then check.push [222,0]
    when 14 then check.push [131,0]
    when 15 then check.push [241,0], [132,0]
    when 16 then check.push [245,0]
    when 17 then check.push [249,0], [133,0]
    when 18 then check.push [250,0], [209,1]
    when 19
      check.push [111,1] if command.parameters[0] == 4
      check.push [122,4] if command.parameters[3] == 4
      check.push [129,0], [303,0]
      (311..322).each{|i| check.push [i,0]} if command.parameters[0] != 0
    when 20 then check.push [321,1]
    when 21
      if command.parameters[0] == 4 && command.parameters[2] == 2
        check.push [111,3]
      end
      check.push [318,2]
      check.push [339,3] if command.parameters[2] == 1
    when 22
      check.push [111,1] if command.parameters[0] == 8
      check.push [122,4] if command.parameters[3] == 3
      check.push [126,0]
      check.push [302,1] if command.parameters[0] == 0
      check.push [605,1] if command.parameters[0] == 0
    when 23
      if command.parameters[0] == 4 && command.parameters[2] == 3
        check.push [111,3]
      end
      check.push [111,1] if command.parameters[0] == 9
      check.push [127,0]
    when 24
      if command.parameters[0] == 4 && command.parameters[2] == 4
        check.push [111,3]
      end
      check.push [111,1] if command.parameters[0] == 10
      check.push [128,0]
    when 25 then check.push [336,1]
    when 26 then check.push [301,0]
    when 27
      if command.parameters[0] == 4 && command.parameters[2] == 5
        check.push [111,3]
      end
      check.push [313,2], [333,2]
    when 28 then check.push [207,1], [337,2]
    when 30 then check.push [117,0]
    when 32
      check.push [111,1] if command.parameters[0] == 0
      check.push [121,0], [121,1], [209,1]
    when 33
      if command.parameters[0] == 1
        check.push [111,1], [201,1], [201,2], [201,3]
        check.push [111,3] if command.parameters[2] != 0
      end
      if command.parameters[1] == 1
        check.push [202,2], [202,3]
      end
      if command.parameters[2] == 1
        check.push [311,3], [312,3], [315,3], [316,3], [331,3], [332,3]
      end
      if command.parameters[3] == 1
        check.push [122,4], [231,4], [231,5], [232,4], [232,5], [317,3]
      end
      check.push [122,0], [122,1]
    when 34 then check.push [201,1] if command.parameters[0] == 0
    end
    return check
  end
  #-----------------------------------------------------------------------------
  # Change Database
  #-----------------------------------------------------------------------------
  def change_database
    update("Updating Databse")
    case @type
    when 1 #animations
      $data_animations.each do |animation|
        next if animation.nil?
        animation.animation_name = change(animation.animation_name,28)
      end
    when 2 #autotiles
      $data_tilesets.each do |tileset|
        next if tileset.nil?
        tileset.autotile_names.each do |autotile|
          autotile = change(autotile,29)
        end
      end
    when 3 #battlebacks
      $data_tilesets.each do |tileset|
        next if tileset.nil?
        tileset.battleback_name = change(tileset.battleback_name,29)
      end
      $data_system.battleback_name = change($data_system.battleback_name,31)
    when 4 #battlers
      $data_actors.each do |actor|
        next if actor.nil?
        actor.battler_name = change(actor.battler_name,19)
      end
      $data_enemies.each do |enemy|
        next if enemy.nil?
        enemy.battler_name = change(enemy.battler_name,25)
      end
      $data_system.battler_name = change($data_system.battler_name,31)
    when 5 #characters
      $data_actors.each do |actor|
        next if actor.nil?
        actor.character_name = change(actor.character_name,19)
      end
    when 6 #fogs
      $data_tilesets.each do |tileset|
        next if tileset.nil?
        tileset.fog_name = change(tileset.fog_name,29)
      end
    when 7 #gameovers
      $data_system.gameover_name = change($data_system.gameover_name,31)
    when 8 #icons
      [$data_skills,$data_items,$data_weapons,$data_armors].each_with_index do |data,i|
        data.each do |d|
          next if d.nil?
          d.icon_name = change(icon_name,21 + i)
        end
      end
    when 9 #panoramas
      $data_tilesets.each do |tileset|
        next if tileset.nil?
        tileset.panorama_name = change(tileset.panorama_name,29)
      end
    when 12 #titles
      $data_system.title_name = change($data_system.title_name,31)
    when 13 #transitions
      $data_system.battle_transition = change($data_system.battle_transition,31)
    when 14 #windowskins
      $data_system.windowskin_name = change($data_system.windowskin_name,31)
    when 15 #bgm
      $data_system.title_bgm = audio($data_system.title_bgm,31)
      $data_system.battle_bgm = audio($data_system.battle_bgm,31)
    when 17 #me
      $data_system.battle_end_me = audio($data_system.battle_end_me,31)
      $data_system.gameover_me = audio($data_system.gameover_me,31)
    when 18 #se
      $data_system.cursor_se = audio($data_system.cursor_se,31)
      $data_system.decision_se = audio($data_system.decision_se,31)
      $data_system.cancel_se = audio($data_system.cancel_se,31)
      $data_system.buzzer_se = audio($data_system.buzzer_se,31)
      $data_system.equip_se = audio($data_system.equip_se,31)
      $data_system.shop_se = audio($data_system.shop_se,31)
      $data_system.save_se = audio($data_system.save_se,31)
      $data_system.load_se = audio($data_system.load_se,31)
      $data_system.battle_start_se = audio($data_system.battle_start_se,31)
      $data_system.escape_se = audio($data_system.escape_se,31)
      $data_system.actor_collapse_se = audio($data_system.actor_collapse_se,31)
      $data_system.enemy_collapse_se = audio($data_system.enemy_collapse_se,31)
      [$data_skills,$data_items].each_with_index do |data,i|
        data.each do |d|
          next if d.nil?
          d.menu_se = audio(d.menu_se,21 + i)
        end
      end
      $data_animations.each do |animation|
        next if animation.nil?
        animation.timings.each do |timing|
          timing.se = audio(timing.se,28)
        end
      end
    when 19 #actors
      $data_system.party_members.each do |id|
        id = change(id,31)
      end
      $data_troops.each do |troop|
        next if troop.nil?
        troop.pages.each do |page|
          if page.condition.actor_valid
            page.condition.actor_id = change(page.condition.actor_id,26)
          end
        end
      end
      $data_system.test_battlers.each do |battler|
        battler.actor_id = change(battler.actor_id,31)
      end
    when 20 #classes
      $data_actors.each do |actor|
        next if actor.nil?
        actor.class_id = change(actor.class_id,31)
      end
    when 21 #skills
      $data.classes.each do |klass|
        next if klass.nil?
        klass.learnings.each do |learning|
          learning.skill_id = change(learning.skill_id,20)
        end
      end
      $data_enemies.each do |enemy|
        next if enemy.nil?
        enemy.actions.each do |action|
          if action.kind == 1
            action.skill_id = change(action.skill_id,25)
          end
        end
      end
    when 22 #items
      $data_enemies.each do |enemy|
        next if enemy.nil?
        if enemy.item_id != 0
          enemy.item_id = change(enemy.item_id,25)
        end
      end
    when 23 #weapons
      $data_actors.each do |actor|
        next if actor.nil?
        actor.weapon_id = change(actor.weapon_id,19)
      end
      $data_classes.each do |klass|
        next if klass.nil?
        klass.weapon_set = include(klass.weapon_set,20)
      end
      $data_enemies.each do |enemy|
        next if enemy.nil?
        if enemy.weapon_id != 0
          enemy.weapon_id = change(enemy.weapon_id,25)
        end
      end
    when 24 #armors
      $data_actors.each do |actor|
        next if actor.nil?
        actor.armor1_id = change(actor.armor1_id,19)
        actor.armor2_id = change(actor.armor2_id,19)
        actor.armor3_id = change(actor.armor3_id,19)
        actor.armor4_id = change(actor.armor4_id,19)
      end
      $data_classes.each do |klass|
        next if klass.nil?
        klass.armor_set = include(klass.armor_set,20)
      end
      $data_enemies.each do |enemy|
        next if enemy.nil?
        if enemy.armor_id != 0
          enemy.armor_id = change(enemy.armor_id,25)
        end
      end
    when 25 #enemies
      $data_troops.each do |troop|
        next if troop.nil?
        troop.members.each do |member|
          member.enemy_id = change(member.enemy_id,26)
        end
      end
    when 26 #troops
      $data_system.test_troop_id = change($data_system.test_troop_id,31)
    when 27 #states
      [$data_classes,$data_enemies].each_with_index do |data, i|
        edit = (i == 0 ? 20 : 25)
        data.each do |d|
          next if d.nil?
          d.state_ranks = table(d.state_ranks,edit)
        end
      end
      [$data_skills,$data_items,$data_weapons,$data_states].each_with_index do |data,i|
        edit = (i < 3 ? 21 + i : 27)
        data.each do |d|
          next if d.nil?
          d.plus_state_set = include(d.plus_state_set,edit)
          d.minus_state_set = include(d.minus_state_set,edit)
        end
      end
      $data_armors.each do |armor|
        next if armor.nil?
        armor.guard_state_set = include(armor.guard_state_set,24)
        armor.auto_state_id = change(armor.auto_state_id,24)
      end
    when 28 #animations
      [$data_skills,$data_items,$data_weapons,$data_enemies].each_with_index do |data,i|
        edit = (i < 3 ? 21 + i : 25)
        data.each do |d|
          next if d.nil?
          d.animation1_id = change(d.animation1_id,edit)
          d.animation2_id = change(d.animation2_id,edit)
        end
      end
      $data_states.each do |state|
        next if state.nil?
        state.animation_id = change(state.animation_id,27)
      end
    when 30 #common events
      [$data_skills,$data_items].each_with_index do |data,i|
        data.each do |d|
          next if d.nil?
          d.common_event_id = change(d.common_event_id,21 + i)
        end
      end
    when 31 #elements
      [$data_classes,$data_enemies].each_with_index do |data, i|
        edit = (i == 0 ? 20 : 25)
        data.each do |d|
          next if d.nil?
          d.element_ranks = table(d.element_ranks,edit)
        end
      end
      [$data_skills,$data_items,$data_weapons].each_with_index do |data,i|
        data.each do |d|
          next if d.nil?
          d.element_set = include(d.element_set,21  + i)
        end
      end
      [$data_armors,$data_states].each_with_index do |data,i|
        edit = (i == 0 ?  24 : 27)
        data.each do |d|
          next if d.nil?
          d.guard_element_set = include(d.guard_element_set,edit)
        end
      end
    when 32 #switches
      $data_common_events.each do |ce|
        next if ce.nil?
        if ce.trigger != 0
          ce.switch_id = change(ce.switch_id,30)
        end
      end
      $data_enemies.each do |enemy|
        next if enemy.nil?
        enemy.actions.each do |action|
          action.condition_switch_id = change(action.condition_switch_id,25)
        end
      end
      $data_troops.each do |troop|
        next if troop.nil?
        troop.pages.each do |page|
          if page.condition.switch_valid
            page.condition.switch_id = change(page.condition.switch_id,26)
          end
        end
      end
    when 34 #map infos
      $data_system.start_map_id = change($data_system.start_map_id,31)
      $data_system.edit_map_id = change($data_system.edit_map_id,31)
    end
  end
  #-----------------------------------------------------------------------------
  # Change
  #-----------------------------------------------------------------------------
  def change(data, id = 0)
    if data == @prev
      data = @new
    elsif @change && data == @new
      data = @prev
    end
    return data
  end
  #-----------------------------------------------------------------------------
  # Audio
  #-----------------------------------------------------------------------------
  def audio(audio, id = 0)
    audio.name = change(audio.name, id)
    return audio
  end
  #-----------------------------------------------------------------------------
  # Table
  #-----------------------------------------------------------------------------
  def table(table, id = 0)
    if @change
      if table[@prev] != table[@new]
        temp = table[@prev]
        table[@prev] = table[@new]
        table[@new] = temp
      end
    else
      unless table[@new] == 3 && table[@prev] == 3
        table[@new] = table[@prev]
        table[@prev] = 3
      end
    end
    return table
  end
  #-----------------------------------------------------------------------------
  # Include
  #-----------------------------------------------------------------------------
  def include(array, id = 0)
    if array.include?(@prev)
      array.delete(@prev) if (@change && !array.include?(@new)) || !@change
      array.push(@new) if !array.include?(@new)
    elsif @change && array.include?(@new)
      array.delete(@new)
      array.push(@prev)
    end
    return array
  end
  #-----------------------------------------------------------------------------
  # Data
  #-----------------------------------------------------------------------------
  def data(data = false, type = 0)
    type = @type if type == 0
    case type
    when 19 then return $data_actors
    when 20 then return $data_classes
    when 21 then return $data_skills
    when 22 then return $data_items
    when 23 then return $data_weapons
    when 24 then return $data_armors
    when 25 then return $data_enemies
    when 26 then return $data_troops
    when 27 then return $data_states
    when 28 then return $data_animations
    when 29 then return $data_tilesets
    when 30 then return $data_common_events
    when 31 then return data ? $data_system : $data_system.elements
    when 32 then return data ? $data_system : $data_system.switches
    when 33 then return data ? $data_system : $data_system.variables
    when 34 then return $data_map_infos
    end
  end
  #-----------------------------------------------------------------------------
  # Object
  #-----------------------------------------------------------------------------
  def object
    case @type
    when 19 then return RPG::Actor.new
    when 20 then return RPG::Class.new
    when 21 then return RPG::Skill.new
    when 22 then return RPG::Item.new
    when 23 then return RPG::Weapon.new
    when 24 then return RPG::Armor.new
    when 25 then return RPG::Enemy.new
    when 26 then return RPG::Troop.new
    when 27 then return RPG::State.new
    when 28 then return RPG::Animation.new
    when 29 then return RPG::Tileset.new
    when 30 then return RPG::CommonEvent.new
    when 31,32,33 then return String.new
    end
  end
  #-----------------------------------------------------------------------------
  # Folder
  #-----------------------------------------------------------------------------
  def folder
    return (@type <= 15 ? 'Graphics' : 'Audio')
  end
  #-----------------------------------------------------------------------------
  # String
  #-----------------------------------------------------------------------------
  def string(data = true, type = 0)
    type = @type if type == 0
    case type
    when 1 then return 'Animations'
    when 2 then return 'Autotiles'
    when 3 then return 'Battlebacks'
    when 4 then return 'Battlers'
    when 5 then return 'Characters'
    when 6 then return 'Fogs'
    when 7 then return 'Gameovers'
    when 8 then return 'Icons'
    when 9 then return 'Panoramas'
    when 10 then return 'Pictures'
    when 11 then return 'Tilesets'
    when 12 then return 'Titles'
    when 13 then return 'Transitions'
    when 14 then return 'Windowskins'
    when 15 then return 'BGM'
    when 16 then return 'BGS'
    when 17 then return 'ME'
    when 18 then return 'SE'
    when 19 then return 'Actors'
    when 20 then return 'Classes'
    when 21 then return 'Skills'
    when 22 then return 'Items'
    when 23 then return 'Weapons'
    when 24 then return 'Armors'
    when 25 then return 'Enemies'
    when 26 then return 'Troops'
    when 27 then return 'States'
    when 28 then return 'Animations'
    when 29 then return 'Tilesets'
    when 30 then return 'CommonEvents'
    when 31 then return (data ? 'ElementNames' : 'System') 
    when 32 then return (data ? 'Switches' : 'System')
    when 33 then return (data ? 'Variables' : 'System')
    when 34 then return 'MapInfos'
    end
  end
  #-----------------------------------------------------------------------------
  # Type
  #-----------------------------------------------------------------------------
  def type(string)
    case string
    when 'Animations' then return 1
    when 'Autotiles' then return 2
    when 'Battlebacks' then return 3
    when 'Battlers' then return 4
    when 'Characters' then return 5
    when 'Fogs' then return 6
    when 'Gameovers' then return 7
    when 'Icons' then return 8
    when 'Panoramas' then return 9
    when 'Pictures' then return 10
    when 'Tilesets' then return 11
    when 'Titles' then return 12
    when 'Transitions' then return 13
    when 'Windowskins' then return 14
    when 'BGM' then return 15
    when 'BGS' then return 16
    when 'ME' then return 17
    when 'SE' then return 18
    when 'Actors' then return 19
    when 'Classes' then return 20
    when 'Skills' then return 21
    when 'Items' then return 22
    when 'Weapons' then return 23
    when 'Armors' then return 24
    when 'Enemies' then return 25
    when 'Troops' then return 26
    when 'States' then return 27
    when 'Animations' then return 28
    when 'Tilesets' then return 29
    when 'Common Events' then return 30
    when 'Element Names' then return 31
    when 'Switches' then return 32
    when 'Variables' then return 33
    when 'Map' then return 34
    end
    return 0
  end
  #-----------------------------------------------------------------------------
  # Update
  #-----------------------------------------------------------------------------
  def update(text)
    @rate += 1
    @progress.fraction = @rate.to_f / ($data_map_infos.size + (@change ? 6 : 5)).to_f
    @progress_text.replace(text)
  end
  #-----------------------------------------------------------------------------
  # Update Database List
  #-----------------------------------------------------------------------------
  def update_database_list
    array = Array.new
    if @type == 34
      data.keys.sort.each do |key|
        array << "#{key}: #{data[key].name}"
      end
    elsif @type > 18
      data.each_with_index do |item, i|
        next if item.nil?
        name = @type > 30 ? item : item.name
        array << "#{i}: #{name}"
      end
    else
      array << 'N/A'
    end
    @database_list.items = array
  end
  #-----------------------------------------------------------------------------
  # Elements
  #-----------------------------------------------------------------------------
  #Background
  background rgb(236,233,216)
  #Progress bar
  stack(:width => 0.6, :left => 100, :top => 220) do
    @progress_text = para('Progress', :align => 'center')
    @progress= progress(:width => 1.0)
  end
  #Change check
  flow(:left => 270, :top => 130) do
    @change_check = check(:checked => true)
    para 'Change Filenames and Swap Data'
  end
  #Overwrite check
  flow(:left => 270, :top => 155) do
    @overwrite_check = check
    para 'Overwrite Existing Filenames'
  end
  #Previous Line
  stack(:left => 50, :top => 10) do
    para('Previous Filename/ID')
    @prev_line = edit_line
  end
  #New Line
  stack(:left => 300, :top => 10) do 
    para('New Filename/ID')
    @new_line = edit_line
  end
  #File Search
  @search = button('File Search', :left => 80, :top => 74) do
    return unless start_check
    file = ask_open_file
    text = type_text = folder_text = String.new
    file.gsub!(FILE_REGEXP) do
      folder_text = $1
      type_text = $2
      text = $3
    end
    if location_check(text, type_text, folder_text)
      @ext = File.extname(text)
      @prev_line.text = File.basename(text, @ext)
      @type = type(type_text)
      @type_list.choose(type_text)
      @database_list.items = ['N/A']
      @database_list.choose('N/A')
    end
  end
  #Start button
  @start = button('Start Swap', :left => 340, :top => 74) do
    swap if start_check && error_check
  end
  #Database list
  stack(:left => 25, :top => 155) do
    para('Database Search')
    @database_list = list_box(:items => ['N/A']) do |list|
      return unless start_check
      unless ['', 'N/A'].include?(list.text)
        list.text.gsub(DATA_REGEXP) {@prev_line.text = $1}
      end
    end
  end
  #Type list
  stack(:left => 25, :top => 100) do
    para('Swap Type')
    @type_list = list_box(:items => [
    '----Graphics----',
    'Animations',
    'Autotiles',
    'Battlebacks',
    'Battlers',
    'Characters',
    'Fogs',
    'Gameovers',
    'Icons',
    'Panoramas',
    'Pictures',
    'Tilesets',
    'Titles',
    'Transitions',
    'Windowskins',
    '----Audio----',
    'BGM',
    'BGS',
    'ME',
    'SE',
    '----Database----',
    'Actors',
    'Classes',
    'Skills',
    'Items',
    'Weapons',
    'Armors',
    'Enemies',
    'Troops',
    'States',
    'Animations',
    'Tilesets',
    'Common Events',
    'Element Names',
    '----Other---',
    'Switches',
    'Variables',
    'Map']) do |list|
      @type = type(list.text)
      update_database_list
    end
  end
end