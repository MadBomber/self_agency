def median
  return 0.0 if @data.nil? || @data.empty?
  
  sorted_data = @data.sort
  length = sorted_data.length
  
  if length.odd?
    sorted_data[length / 2].to_f
  else
    mid1 = sorted_data[length / 2 - 1]
    mid2 = sorted_data[length / 2]
    (mid1 + mid2).to_f / 2.0
  end
end