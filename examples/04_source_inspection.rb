#!/usr/bin/env ruby
# frozen_string_literal: true

# 04_source_inspection.rb — Viewing generated source code
#
# Demonstrates:
#   - _source_for on an instance (instance-level lookup)
#   - _source_for on the class (class-level lookup via ClassMethods)
#   - Original description appears as a comment header
#   - Fallback to method_source for file-defined methods
#
# Requires a running Ollama instance with the configured model.

require_relative "lib/setup"

class MathHelper
  include SelfAgency

  # Multiplies a number by two.
  def double(n)
    n * 2
  end
end

helper = MathHelper.new

puts "=== Generate a method ==="
description = "an instance method named 'square' that accepts an integer n and returns n * n"
helper._(description)
puts "helper.square(5) = #{helper.square(5)}"
puts

puts "=== Instance-level _source_for ==="
puts helper._source_for(:square)
puts

puts "=== Class-level _source_for ==="
puts MathHelper._source_for(:square)
puts

puts "=== Fallback to method_source for file-defined methods ==="
puts helper._source_for(:double)
puts

puts "=== _source_for returns nil for unknown methods ==="
puts helper._source_for(:nonexistent).inspect
