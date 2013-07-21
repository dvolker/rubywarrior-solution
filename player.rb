class Player


  def play_turn(warrior)
    

    [:forward,:backward,:left,:right].each do |dir|

      if dir != warrior.direction_of_stairs and warrior.feel(dir).enemy? then
        warrior.bind! dir
        return 
      end

    end
    # if warrior.feel(warrior.direction_of_stairs).captive? then
    #   warrior.rescue! warrior.direction_of_stairs
    # els
    if warrior.feel(warrior.direction_of_stairs).enemy? then
      warrior.attack! warrior.direction_of_stairs
    elsif warrior.health < 20 then
      warrior.rest!
    else
      if warrior.feel(:right).captive? then
        warrior.rescue! :right
        return
      end
      
      warrior.walk! warrior.direction_of_stairs
    end
  end

  def rescue_captive(warrior)
    [:forward,:backward,:left,:right].each do |dir|
      if warrior.feel(dir).captive? then
        warrior.rescue!(dir)
        return
      end
    end
  end

  def nearby_enemy_count(warrior)
    count = 0
    [:forward,:backward,:left,:right].each do |dir|
      if warrior.feel(dir).enemy? then
        count += 1
      end
    end
    count
  end

  def nearby_captive_count(warrior)
    count = 0
    [:forward,:backward,:left,:right].each do |dir|
      if warrior.feel(dir).captive? then
        count += 1
      end
    end
    count
  end

end
