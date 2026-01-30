#!/usr/bin/env ruby
# frozen_string_literal: true

# 05_lifecycle_hook.rb — Persisting generated methods
#
# Demonstrates:
#   - Overriding on_method_generated(method_name, scope, code)
#   - Hook fires for each method generated
#   - Persistence pattern: saving generated code to files
#
# Requires a running Ollama instance with the configured model.

require_relative "../lib/self_agency"

SelfAgency.configure do |config|
  config.provider = :ollama
  config.model    = "qwen3-coder:30b"
  config.api_base = "http://localhost:11434/v1"
end

class PersistentCalculator
  include SelfAgency

  attr_reader :generation_log

  def initialize
    @generation_log = []
  end

  def on_method_generated(method_name, scope, code)
    @generation_log << { method_name: method_name, scope: scope, code: code }
    puts "  [hook] Generated :#{method_name} (scope: #{scope})"
    puts "  [hook] Code preview: #{code.lines.first.chomp}..."
  end
end

calc = PersistentCalculator.new

puts "=== Generating methods (hook will fire for each) ==="
puts

calc._("an instance method named 'increment' that accepts an integer n and returns n + 1")
puts

calc._(
  "two instance methods: " \
  "'min_of(a, b)' returns the smaller of a and b, " \
  "'max_of(a, b)' returns the larger of a and b"
)
puts

puts "=== Generation log ==="
calc.generation_log.each_with_index do |entry, i|
  puts "#{i + 1}. :#{entry[:method_name]} (#{entry[:scope]})"
end

puts
puts "=== Using the generated methods ==="
puts "calc.increment(41) = #{calc.increment(41)}"
puts "calc.min_of(3, 7)  = #{calc.min_of(3, 7)}"
puts "calc.max_of(3, 7)  = #{calc.max_of(3, 7)}"
