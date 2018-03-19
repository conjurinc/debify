module DebifyWorld
  attr_accessor :containers, :networks

  def initialize
    @containers = []
    @networks = []
  end
end

World(DebifyWorld)
