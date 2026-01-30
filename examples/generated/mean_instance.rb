def mean
  return 0.0 if @data.empty?
  @data.sum.to_f / @data.count
end