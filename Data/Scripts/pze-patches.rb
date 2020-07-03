=begin block
  Script "Game_Temp"
  Insert_Before "57"
  Expect "  #--------------------------------------------------------------------------"
=end
  #-------------Edit----------------
  attr_accessor :below_hero
  #/-------------Edit---------------

=begin block
  Script "Game_Temp"
  Insert_Before "106"
  Expect "  end"
=end
    #-------------Edit----------------
    @below_hero = false
    #/------------Edit----------------
