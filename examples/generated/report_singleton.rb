def report
  data_set = data
  count = data_set.length
  mean_value = mean
  median_value = median
  std_dev_value = standard_deviation
  
  "Data Count: #{count}\nMean: #{mean_value}\nMedian: #{median_value}\nStandard Deviation: #{std_dev_value}"
end