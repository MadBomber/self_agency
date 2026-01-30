#!/usr/bin/env ruby
# frozen_string_literal: true

# 02_multiple_methods.rb — Multiple methods from one call
#
# Demonstrates:
#   - Generating several related methods in a single _() call
#   - _() returns an Array of Symbols
#   - Calling each generated method
#
# Requires a running Ollama instance with the configured model.

require_relative "../lib/self_agency"

SelfAgency.configure do |config|
  config.provider = :ollama
  config.model    = "qwen3-coder:30b"
  config.api_base = "http://localhost:11434/v1"
end

class Arithmetic
  include SelfAgency
end

arith = Arithmetic.new

puts "Generating four arithmetic methods in a single call..."
method_names = arith._(
  "create four instance methods: " \
  "'add(a, b)' returns a + b, " \
  "'subtract(a, b)' returns a - b, " \
  "'multiply(a, b)' returns a * b, " \
  "'divide(a, b)' returns a.to_f / b (raises ZeroDivisionError if b is zero)"
)

puts "_() returned: #{method_names.inspect}"
puts "Type: #{method_names.class}"
puts "Count: #{method_names.length} methods generated"
puts

method_names.each do |name|
  puts "  #{name} is now defined"
end

puts
puts "arith.add(10, 3)      = #{arith.add(10, 3)}"
puts "arith.subtract(10, 3) = #{arith.subtract(10, 3)}"
puts "arith.multiply(10, 3) = #{arith.multiply(10, 3)}"
puts "arith.divide(10, 3)   = #{arith.divide(10, 3)}"
