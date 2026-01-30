#!/usr/bin/env ruby
# frozen_string_literal: true

# 09_method_override.rb — Overriding existing methods
#
# Demonstrates:
#   - Defining a class with an existing method
#   - Generating a method with the same name overrides the original
#   - Prepend-based MRO means the generated method takes priority
#   - _source_for returns the new (generated) source
#
# Requires a running Ollama instance with the configured model.

require_relative "../lib/self_agency"

SelfAgency.configure do |config|
  config.provider = :ollama
  config.model    = "qwen3-coder:30b"
  config.api_base = "http://localhost:11434/v1"
end

class Formatter
  include SelfAgency

  def greet(name)
    "Hello, #{name}"
  end
end

fmt = Formatter.new

puts "=== Before override ==="
puts "fmt.greet('World') = #{fmt.greet('World')}"
puts
puts "Source (from file):"
puts fmt._source_for(:greet)
puts

puts "=== Generating a replacement method with the same name ==="
fmt._(
  "an instance method named 'greet' that accepts a name parameter " \
  "and returns the string 'Greetings, <name>! Welcome aboard.' " \
  "(this should override the existing greet method)"
)

puts
puts "=== After override ==="
puts "fmt.greet('World') = #{fmt.greet('World')}"
puts
puts "Source (now LLM-generated):"
puts fmt._source_for(:greet)
puts

puts "=== MRO shows prepended module ==="
puts "Formatter ancestors:"
Formatter.ancestors.first(5).each_with_index do |ancestor, i|
  puts "  #{i}. #{ancestor}"
end
