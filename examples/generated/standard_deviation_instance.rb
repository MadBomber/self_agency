def standard_deviation
  return 0.0 if @data.nil? || @data.empty?
  
  mean = @data.sum.to_f / @data.length
  squared_differences = @data.map { |value| (value - mean) ** 2 }
  mean_of_squared_differences = squared_differences.sum.to_f / @data.length
  Math.sqrt(mean_of_squared_differences)
end