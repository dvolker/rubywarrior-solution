## This is ugly, I know. It's intended to beat the game rubywarrior, not be maintainable. ;)


class Player
  @@dirs = [:forward,:right,:backward,:left]
  @@rest_threshold = 5
  @@rest_until = 16

  @last_bind
  @moves
  @action 
  @last_safe_space
  @current_space 
  @nearby 

  def walk(dir)
    @last_bind = nil
    @current_space = @warrior.look(dir).first #@nearby[dir].first
    if @moves.nil? then
      @moves = [dir]
    else
      @moves.push(dir)
    end
    @warrior.walk! dir
  end
  
  def play_turn(warrior)
    @warrior = warrior
    @turn = 0 if @turn.nil?
    @turn += 1
    
    scan_spaces
    space_is_safe?
    unless hear_ticking?(warrior) and @turn > 16 then
      return if rest_if_needed 
    end


    #puts "DIST: #{distance_to_nearest_explosive(warrior)}"
    #puts "LAST SAFE SPACE: #{@last_safe_space.inspect}"
    return if asplode_if_needed(warrior)

    if hear_ticking?(warrior) then
      if warrior.feel(direction_of_ticking(warrior)).captive? then
        warrior.rescue! direction_of_ticking(warrior)
        return
      end
      dir = direction_of_ticking(warrior)
      if warrior.feel(dir).enemy? then
        if @turn > 15 then
          puts "TURBO MODE!"
          warrior.attack! dir 
        else
          bind_all_but_dir(warrior, dir)
        end
        return
      end

      if not @moves.nil? and opposite_dir(dir) == @moves.last then
        dir = find_empty_space(warrior, dir)
      end
      # if distance_to_nearest_explosive(warrior) > 2 then
      #   walk(dir) unless rest_if_needed(warrior)
      # else
        walk(dir) 
      # end
      return
    end

    if bind_and_attack(warrior) then
      return
    end

    if warrior.listen.count > 0 then
      walk direction_no_stairs(warrior, warrior.direction_of(warrior.listen.first))
    else
      walk warrior.direction_of_stairs
    end

  end

  def walk_toward(space)
    walk direction_no_stairs(@warrior, @warrior.direction_of(space))
  end

  def scan_spaces()
    @nearby = {}
    @@dirs.each do |dir|
      @nearby[dir] = @warrior.look(dir)
    end
  end

  def space_is_safe?()
    if @last_safe_space.nil? then
      @last_safe_space = @current_space
    end

    @@dirs.each do |dir|
      if @warrior.feel(dir).enemy? then
        return false
      end
    end
    @last_safe_space = @current_space
    true
  end

  def bind_all_but_dir(warrior, direction)
    [:forward,:right,:backward,:left].each do |dir|
      if dir == direction then
        next
      end
      if warrior.feel(dir).enemy? then
        warrior.bind! dir 
        return
      end
    end
    if warrior.feel(direction).enemy? then
      warrior.attack! direction 
    end
  end

  def direction_no_stairs(warrior, direction)
    if warrior.feel(direction).stairs? then
      return find_empty_space(warrior, direction)
    end
    return direction
  end

  def opposite_dir(direction)
    case direction
    when :forward
      return :backward
    when :backward
      return :forward
    when :left
      return :right
    when :right
      return :left
    end
  end

  def find_empty_space(warrior = @warrior, direction=nil) 
    [:forward,:right,:backward,:left].each do |dir|
      if direction == dir then
        next
      end
      if warrior.feel(dir).empty? then
        return dir 
      end
    end
    return nil
  end

  def hear_ticking?(warrior = @warrior)
    warrior.listen.each do |space|
      if space.ticking? then
        return true
      end
    end
    return false
  end

  def direction_of_ticking(warrior)
    warrior.listen.each do |space|
      if space.ticking? then
        dir = warrior.direction_of(space)
        if warrior.feel(dir).captive? or warrior.feel(dir).empty? \
            or warrior.feel(dir).enemy? then
          return dir 
        else
          return find_empty_space(warrior, dir)
        end
      end
    end

  end

  def distance_to_nearest_explosive(warrior)
    mindist = 999
    warrior.listen.each do |s|
      if s.ticking? then
        dist = warrior.distance_of(s)
        mindist = dist if dist < mindist
      end
    end
    mindist 
  end

  def rest_if_needed(warrior = @warrior)
    case @action
    when :going_to_rest
      if warrior.direction_of(@last_safe_space).nil? then
        puts "Resting!"
        @action = :resting
        return rest_if_needed
      else
        if space_is_safe? then
          puts "Found safe space, resting..."
          @action = :resting
          return rest_if_needed
        end
        puts "Moving toward safe space..."
        # walk_toward(@last_safe_space)
        @warrior.walk! opposite_dir(@moves.pop)  # @warrior.direction_of(@last_safe_space)
        return true
      end
    when :resting
      if warrior.health < @@rest_until then
        warrior.rest!
        return true
      else
        puts "All healed!"
        @action = nil
      end
    when nil
      if warrior.health < @@rest_threshold then
        if space_is_safe? then
          puts "Need to rest and this space looks safe..."
          if hear_ticking? then
            puts "  but I hear ticking!"
            return false
          end
          @action = :resting
          return rest_if_needed
        elsif nearby_enemy_count == 1 then
          puts "Only one enemy here. binding him so I can rest."
          @last_bind = nearest_enemy_direction
          @warrior.bind! nearest_enemy_direction
          @action = :resting
          return true
        end
        if @moves.nil? then
          puts "Need to rest but nowhere to go!"
          if find_empty_space(@warrior).nil? then
            puts "Let's keep fighting"
            return false
          end
          puts "Trying random space!" 
          @action = :resting
        
          walk find_empty_space(@warrior)
          return true
        else
          puts "Gonna go rest!"
          @action = :going_to_rest
          return rest_if_needed
        end
      end
    end

    false
  end

  def nearest_enemy_direction
    @@dirs.each do |dir|
      if @warrior.feel(dir).enemy? then
        return dir 
      end
    end
    return nil
  end

  def asplode_if_needed(warrior)
    return false if warrior.health <= 4
    return false if warrior.health <= 8 and find_empty_space.nil? # Surrounded!
    [:forward,:backward,:left,:right].each do |dir|
      enemy_count = 0
      warrior.look(dir)[0..1].each { |s| enemy_count += 1 if s.enemy? }
      if enemy_count >= 2 and distance_to_nearest_explosive(warrior) > 2 then
        warrior.detonate!(dir) 
        return true
      end
    end
    false
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

    # if warrior.health < 20 then
    #   warrior.rest!
    #   return true
    # end

    [:forward,:backward,:left,:right].each do |dir|
      if warrior.feel(dir).captive? then
        if @last_bind = dir then
          warrior.attack! dir 
        else
          warrior.rescue! dir   
        end
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

  def nearby_enemy_count(warrior = @warrior)
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
