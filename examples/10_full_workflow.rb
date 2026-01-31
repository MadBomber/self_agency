#!/usr/bin/env ruby
# frozen_string_literal: true

# 10_full_workflow.rb — Complete real-world workflow
#
# Demonstrates:
#   - Building a domain class with multiple generated methods
#   - Using different scopes (instance, singleton, class)
#   - Lifecycle hook to save generated code to files
#   - Source inspection for all generated methods
#   - End-to-end usage combining all features
#
# Requires a running Ollama instance with the configured model.

require "fileutils"
require_relative "lib/setup"

# Output directory for persisted generated code
GENERATED_DIR = File.join(__dir__, "generated")
FileUtils.mkdir_p(GENERATED_DIR)

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

puts "=== Building a StatisticsCalculator ==="
calc = StatisticsCalculator.new([10, 20, 30, 40, 50, 60, 70, 80, 90, 100])
puts "Data: #{calc.data.inspect}"
puts

# --- Instance methods ---
puts "--- Generating instance methods ---"

calc._(
  "an instance method named 'mean' that calculates and returns the " \
  "arithmetic mean of the @data array as a Float"
)

calc._(
  "an instance method named 'median' that returns the median value " \
  "of the @data array (sort the array, return the middle element for " \
  "odd length, or average of two middle elements for even length) as a Float"
)

calc._(
  "an instance method named 'standard_deviation' that calculates and " \
  "returns the population standard deviation of @data as a Float " \
  "(square root of the mean of squared differences from the mean)"
)
puts

# --- Class method ---
puts "--- Generating a class method ---"
calc._(
  "a class method named 'self.from_range' that accepts two integers " \
  "(low, high) and returns a new StatisticsCalculator instance " \
  "initialized with (low..high).to_a",
  scope: :class
)
puts

# --- Singleton method ---
puts "--- Generating a singleton method ---"
calc._(
  "an instance method named 'report' that returns a multi-line string " \
  "summarizing the data count, mean, median, and standard_deviation " \
  "by calling the existing instance methods",
  scope: :singleton
)
puts

# --- Use the generated methods ---
puts "=== Using generated methods ==="
puts "Mean:               #{calc.mean}"
puts "Median:             #{calc.median}"
puts "Standard deviation: #{calc.standard_deviation}"
puts

puts "=== Class method ==="
range_calc = StatisticsCalculator.from_range(1, 5)
puts "StatisticsCalculator.from_range(1, 5).data = #{range_calc.data.inspect}"
puts "Mean of 1..5: #{range_calc.mean}"
puts

puts "=== Singleton report (only on this instance) ==="
puts calc.report
puts

other = StatisticsCalculator.new([1, 2, 3])
puts "other.respond_to?(:report) = #{other.respond_to?(:report)}  (singleton — not available)"
puts

# --- Inspect source ---
puts "=== Source inspection ==="
[:mean, :median, :standard_deviation].each do |name|
  puts "--- #{name} ---"
  puts calc._source_for(name)
  puts
end

# --- List saved files ---
puts "=== Saved generated code ==="
Dir.glob(File.join(GENERATED_DIR, "*.rb")).sort.each do |path|
  puts "  #{path}"
end
