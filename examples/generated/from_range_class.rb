def self.from_range(low, high)
  new((low..high).to_a)
end