#!/usr/bin/env ruby
# frozen_string_literal: true

# 01_basic_usage.rb — Single method generation
#
# Demonstrates:
#   - include SelfAgency
#   - _() to generate a method from a description
#   - Calling the generated method
#
# Requires a running Ollama instance with the configured model.

require_relative "lib/setup"

class Calculator
  include SelfAgency
end

calc = Calculator.new

puts "Generating a method to add two integers..."
method_names = calc._("an instance method named 'add' that accepts two integer parameters a and b, and returns their sum")

puts "Generated methods: #{method_names.inspect}"
puts "calc.add(3, 7) = #{calc.add(3, 7)}"
puts "calc.add(-1, 1) = #{calc.add(-1, 1)}"
puts "calc.add(100, 200) = #{calc.add(100, 200)}"
