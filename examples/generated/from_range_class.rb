def self.from_range(low, high)
  range = (low..high)
  array = range.to_a
  StatisticsCalculator.new(array)
end