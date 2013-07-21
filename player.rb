class Player


  def play_turn(warrior)
    if bind_and_attack(warrior) then
      return
    end

    if warrior.listen.count > 0 then
      warrior.walk! direction_no_stairs(warrior, warrior.direction_of(warrior.listen.first))
    else
      warrior.walk! warrior.direction_of_stairs
    end

  end

  def direction_no_stairs(warrior, direction)
    if warrior.feel(direction).stairs? then
      return find_empty_space(warrior, direction)
    end
    return direction
  end

  def find_empty_space(warrior, direction) 
    [:forward,:right,:backward,:left].each do |dir|
      if direction == dir then
        next
      end
      if warrior.feel(dir).empty? then
        return dir 
      end
    end
  end



  def bind_and_attack(warrior)
    [:forward,:backward,:left,:right].each do |dir|
      if warrior.feel(dir).enemy? then
        if nearby_enemy_count(warrior) == 1 then
          warrior.attack!(dir)
          return true
        else 
          warrior.bind!(dir)
          return true
        end
      end
    end

    if warrior.health < 20 then
      warrior.rest!
      return true
    end

    [:forward,:backward,:left,:right].each do |dir|
      if warrior.feel(dir).captive? then
        warrior.rescue! dir   
        return true
      end
    end
    return false
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
