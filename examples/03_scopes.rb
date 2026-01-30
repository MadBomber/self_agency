#!/usr/bin/env ruby
# frozen_string_literal: true

# 03_scopes.rb — Instance, singleton, and class scopes
#
# Demonstrates:
#   - scope: :instance  — available to all instances
#   - scope: :singleton — available to only one instance
#   - scope: :class     — available on the class itself
#   - Singleton methods are NOT available on other instances
#
# Requires a running Ollama instance with the configured model.

require_relative "../lib/self_agency"

SelfAgency.configure do |config|
  config.provider = :ollama
  config.model    = "qwen3-coder:30b"
  config.api_base = "http://localhost:11434/v1"
end

class Greeter
  include SelfAgency
end

alice = Greeter.new
bob   = Greeter.new

# --- Instance scope (default) ---
puts "=== Instance scope ==="
alice._("an instance method named 'hello' that returns the string 'Hello, world!'")
puts "alice.hello = #{alice.hello}"
puts "bob.hello   = #{bob.hello}  (available to all instances)"
puts

# --- Singleton scope ---
puts "=== Singleton scope ==="
alice._("an instance method named 'secret' that returns the string 'Alice only'", scope: :singleton)
puts "alice.secret = #{alice.secret}"
puts "bob.respond_to?(:secret) = #{bob.respond_to?(:secret)}  (NOT available on other instances)"
puts

# --- Class scope ---
puts "=== Class scope ==="
alice._("a class method named 'self.class_greeting' that returns 'Greetings from Greeter'", scope: :class)
puts "Greeter.class_greeting = #{Greeter.class_greeting}"
