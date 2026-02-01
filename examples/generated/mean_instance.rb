def mean
  return Float::NAN if @data.empty?
  @data.sum.to_f / @data.size
end