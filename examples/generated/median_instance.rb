def median
  return 0.0 if @data.nil? || @data.empty?
  
  sorted_data = @data.sort
  length = sorted_data.length
  
  if length.odd?
    middle_index = (length - 1) / 2
    sorted_data[middle_index].to_f
  else
    upper_middle_index = length / 2
    lower_middle_index = upper_middle_index - 1
    (sorted_data[upper_middle_index] + sorted_data[lower_middle_index]) / 2.0
  end
end