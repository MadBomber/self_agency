#!/usr/bin/env ruby
# frozen_string_literal: true

# 08_class_context.rb — Instance variable and method awareness
#
# Demonstrates:
#   - The LLM receives class context (class name, ivars, public methods)
#   - Generated methods can reference existing instance variables
#   - Class introspection drives smarter code generation
#
# Requires a running Ollama instance with the configured model.

require_relative "../lib/self_agency"

SelfAgency.configure do |config|
  config.provider = :ollama
  config.model    = "qwen3-coder:30b"
  config.api_base = "http://localhost:11434/v1"
end

class BankAccount
  include SelfAgency

  attr_reader :owner, :balance

  def initialize(owner, balance)
    @owner   = owner
    @balance = balance
  end

  def deposit(amount)
    @balance += amount
  end
end

account = BankAccount.new("Alice", 1000)

# Show what the LLM will see as context
vars = account.send(:self_agency_generation_vars)
puts "=== Class context sent to LLM ==="
puts "  class_name: #{vars[:class_name]}"
puts "  ivars:      #{vars[:ivars]}"
puts "  methods:    #{vars[:methods]}"
puts

puts "=== Generating a method that uses existing instance variables ==="
account._(
  "an instance method named 'summary' that returns a string like " \
  "'Account for <owner>: $<balance>' using the @owner and @balance instance variables"
)

puts account.summary
puts

puts "=== Generating a method that complements existing methods ==="
account._(
  "an instance method named 'withdraw' that accepts an amount, " \
  "raises a RuntimeError with 'Insufficient funds' if amount > @balance, " \
  "otherwise decreases @balance by amount and returns the new balance"
)

puts "Balance before withdraw: $#{account.balance}"
puts "Withdrawing $200..."
puts "Balance after withdraw:  $#{account.withdraw(200)}"

begin
  account.withdraw(999_999)
rescue RuntimeError => e
  puts "Caught expected error: #{e.message}"
end
