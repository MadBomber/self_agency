def standard_deviation
  return 0.0 if @data.nil? || @data.empty?
  
  mean = @data.sum.to_f / @data.length
  squared_differences = @data.map { |x| (x - mean) ** 2 }
  variance = squared_differences.sum.to_f / squared_differences.length
  Math.sqrt(variance)
end