#!/usr/bin/env ruby
# frozen_string_literal: true

# 06_configuration.rb — Configuration options
#
# Demonstrates:
#   - All configurable options with their defaults
#   - Changing provider, model, timeouts, retries
#   - SelfAgency.reset! and SelfAgency.ensure_configured!
#   - Custom template_directory configuration
#
# This example does NOT require a running Ollama instance for
# the configuration inspection parts. Only the final generation
# call requires a live LLM.

require_relative "../lib/self_agency"

puts "=== Default configuration (before configure) ==="
SelfAgency.reset!
cfg = SelfAgency.configuration
puts <<~DEFAULTS
  provider:           #{cfg.provider.inspect}
  model:              #{cfg.model.inspect}
  api_base:           #{cfg.api_base.inspect}
  request_timeout:    #{cfg.request_timeout}
  max_retries:        #{cfg.max_retries}
  retry_interval:     #{cfg.retry_interval}
  template_directory: #{cfg.template_directory}
DEFAULTS

puts "=== ensure_configured! before configure ==="
begin
  SelfAgency.ensure_configured!
rescue SelfAgency::Error => e
  puts "Caught expected error: #{e.message}"
end
puts

puts "=== Configuring with custom values ==="
SelfAgency.configure do |config|
  config.provider        = :ollama
  config.model           = "qwen3-coder:30b"
  config.api_base        = "http://localhost:11434/v1"
  config.request_timeout = 60
  config.max_retries     = 3
  config.retry_interval  = 1.0
end

cfg = SelfAgency.configuration
puts <<~CUSTOM
  provider:           #{cfg.provider.inspect}
  model:              #{cfg.model.inspect}
  api_base:           #{cfg.api_base.inspect}
  request_timeout:    #{cfg.request_timeout}
  max_retries:        #{cfg.max_retries}
  retry_interval:     #{cfg.retry_interval}
  template_directory: #{cfg.template_directory}
CUSTOM

puts "=== ensure_configured! after configure ==="
SelfAgency.ensure_configured!
puts "No error — configuration is active."
puts

puts "=== reset! restores defaults ==="
SelfAgency.reset!
cfg = SelfAgency.configuration
puts "provider after reset: #{cfg.provider.inspect}"
puts "model after reset:    #{cfg.model.inspect}"
puts

begin
  SelfAgency.ensure_configured!
rescue SelfAgency::Error => e
  puts "ensure_configured! after reset: #{e.message}"
end
puts

puts "=== Custom template directory ==="
SelfAgency.configure do |config|
  config.provider           = :ollama
  config.model              = "qwen3-coder:30b"
  config.api_base           = "http://localhost:11434/v1"
  config.template_directory = "/tmp/my_custom_prompts"
end
puts "template_directory: #{SelfAgency.configuration.template_directory}"
puts

# Restore standard config for any follow-up usage
SelfAgency.reset!
SelfAgency.configure do |config|
  config.provider = :ollama
  config.model    = "qwen3-coder:30b"
  config.api_base = "http://localhost:11434/v1"
end
puts "=== Configuration restored for live usage ==="
puts "Ready to generate methods (requires running Ollama)."
