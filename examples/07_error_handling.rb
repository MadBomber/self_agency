#!/usr/bin/env ruby
# frozen_string_literal: true

# 07_error_handling.rb — Error classes and rescue patterns
#
# Demonstrates:
#   - The SelfAgency error hierarchy
#   - Rescuing GenerationError, ValidationError, SecurityError
#   - Calling _() before configure raises SelfAgency::Error
#   - Defensive usage patterns
#
# This example does NOT require a running Ollama instance.

require_relative "../lib/self_agency"

puts "=== Error hierarchy ==="
puts <<~HIERARCHY
  SelfAgency::Error          < StandardError
  SelfAgency::GenerationError < SelfAgency::Error
  SelfAgency::ValidationError < SelfAgency::Error
  SelfAgency::SecurityError   < SelfAgency::Error
HIERARCHY

puts "Verification:"
puts "  GenerationError < Error: #{SelfAgency::GenerationError < SelfAgency::Error}"
puts "  ValidationError < Error: #{SelfAgency::ValidationError < SelfAgency::Error}"
puts "  SecurityError   < Error: #{SelfAgency::SecurityError < SelfAgency::Error}"
puts "  Error < StandardError:   #{SelfAgency::Error < StandardError}"
puts

# --- Calling _() before configure ---
puts "=== Calling _() before configure ==="
SelfAgency.reset!

class Widget
  include SelfAgency
end

begin
  Widget.new._("a method")
rescue SelfAgency::Error => e
  puts "Caught SelfAgency::Error: #{e.message}"
end
puts

# --- Validation errors via private helpers ---
puts "=== ValidationError examples ==="
SelfAgency.configure do |config|
  config.provider = :ollama
  config.model    = "qwen3-coder:30b"
  config.api_base = "http://localhost:11434/v1"
end

widget = Widget.new

# Empty code
begin
  widget.send(:self_agency_validate!, "")
rescue SelfAgency::ValidationError => e
  puts "Empty code:    #{e.class} — #{e.message}"
end

# Missing def...end
begin
  widget.send(:self_agency_validate!, "puts 'hello'")
rescue SelfAgency::ValidationError => e
  puts "No def...end:  #{e.class} — #{e.message}"
end

# Syntax error
begin
  widget.send(:self_agency_validate!, "def broken\n  if true\nend")
rescue SelfAgency::ValidationError => e
  puts "Syntax error:  #{e.class} — #{e.message}"
end
puts

# --- Security errors ---
puts "=== SecurityError examples ==="

dangerous_samples = {
  "system call" => "def hack\n  system('ls')\nend",
  "File access" => "def hack\n  File.read('/etc/passwd')\nend",
  "eval usage"  => "def hack\n  eval('1+1')\nend",
  "require"     => "def hack\n  require 'socket'\nend",
}

dangerous_samples.each do |label, code|
  begin
    widget.send(:self_agency_validate!, code)
  rescue SelfAgency::SecurityError => e
    puts "#{label.ljust(14)}: #{e.class} — #{e.message}"
  end
end
puts

# --- Catching all SelfAgency errors with a single rescue ---
puts "=== Catching all errors with rescue SelfAgency::Error ==="
begin
  raise SelfAgency::SecurityError, "example security violation"
rescue SelfAgency::Error => e
  puts "Caught via base class: #{e.class} — #{e.message}"
end
