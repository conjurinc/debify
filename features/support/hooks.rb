Before do
  # Using "announce" causes massive warnings on 1.9.2
  @puts = true
  @original_rubylib = ENV['RUBYLIB']
  ENV['RUBYLIB'] = LIB_DIR + File::PATH_SEPARATOR + ENV['RUBYLIB'].to_s
end

After do
  ENV['RUBYLIB'] = @original_rubylib
end

Around do |scenario, block|
  # Note that self in an Around hook is the instance of the world
  # (here, a DebifyWorld) for the current scenario.
  initialize
  begin
    block.call
  ensure
    unless ENV['KEEP_CONTAINERS']
      containers.each do |c|
        c.remove(force: true)
      end
      
      networks.each do |n|
        n.remove
      end
    end
  end
end
