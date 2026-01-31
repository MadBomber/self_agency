# Example 10: Full Workflow

A complete real-world workflow that combines all SelfAgency features: multiple scopes, lifecycle hooks, source inspection, and file persistence.

**Source:** `examples/10_full_workflow.rb`

## Overview

Builds a `StatisticsCalculator` class that:

1. Generates instance methods (`mean`, `median`, `standard_deviation`)
2. Generates a class method (`self.from_range`)
3. Generates a singleton method (`report`)
4. Persists all generated code to files via `on_method_generated`
5. Inspects source for all generated methods

## The Class

```ruby
class StatisticsCalculator
  include SelfAgency

  attr_reader :data

  def initialize(data = [])
    @data = data.dup
  end

  def on_method_generated(method_name, scope, code)
    filename = "#{method_name}_#{scope}.rb"
    filepath = File.join(GENERATED_DIR, filename)
    File.write(filepath, code)
    puts "  [saved] #{filepath}"
  end
end
```

## What It Generates

### Instance Methods

```ruby
calc = StatisticsCalculator.new([10, 20, 30, 40, 50, 60, 70, 80, 90, 100])

calc._("an instance method named 'mean' that calculates the arithmetic mean of @data as a Float")
calc._("an instance method named 'median' that returns the median value of @data as a Float")
calc._("an instance method named 'standard_deviation' that returns the population standard deviation of @data as a Float")
```

### Class Method

```ruby
calc._(
  "a class method named 'self.from_range' that accepts (low, high) " \
  "and returns a new StatisticsCalculator initialized with (low..high).to_a",
  scope: :class
)

range_calc = StatisticsCalculator.from_range(1, 5)
range_calc.data  #=> [1, 2, 3, 4, 5]
```

### Singleton Method

```ruby
calc._(
  "a method named 'report' that returns a multi-line summary " \
  "of count, mean, median, and standard_deviation",
  scope: :singleton
)

puts calc.report
# Only available on this specific calc instance
other = StatisticsCalculator.new([1, 2, 3])
other.respond_to?(:report)  #=> false
```

## Generated Files

The lifecycle hook saves each method to the `examples/generated/` directory:

```
examples/generated/
  mean_instance.rb
  median_instance.rb
  standard_deviation_instance.rb
  from_range_class.rb
  report_singleton.rb
```

## Source Inspection

After generation, the source for each method can be retrieved:

```ruby
[:mean, :median, :standard_deviation].each do |name|
  puts "--- #{name} ---"
  puts calc._source_for(name)
end
```
