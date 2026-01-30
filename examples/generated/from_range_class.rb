def self.from_range(low, high)
  new_instance = self.new
  new_instance.instance_variable_set(:@data, (low..high).to_a)
  new_instance
end