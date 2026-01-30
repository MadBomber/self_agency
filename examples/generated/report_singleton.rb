def report
  data = data()
  count = data.count
  mean = mean()
  median = median()
  standard_deviation = standard_deviation()
  
  "Statistical Summary Report
=================
Count: #{count}
Mean: #{mean.round(2)}
Median: #{median.round(2)}
Standard Deviation: #{standard_deviation.round(2)}"
end