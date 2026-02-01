def median
  return 0.0 if @data.nil? || @data.empty?
  
  sorted_data = @data.sort
  length = sorted_data.length
  
  if length.odd?
    middle_index = length / 2
    sorted_data[middle_index].to_f
  else
    right_middle_index = length / 2
    left_middle_index = right_middle_index - 1
    (sorted_data[left_middle_index] + sorted_data[right_middle_index]).to_f / 2.0
  end
end