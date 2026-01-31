# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/test/"
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "self_agency"

require "minitest/autorun"
require "debug_me"
include DebugMe

# Shared test fixtures

class SampleClass
  include SelfAgency

  def file_defined_method
    "from file"
  end

  # Adds two numbers together.
  # Returns the sum.
  def commented_method(a, b)
    a + b
  end
end

# A subclass that records on_method_generated calls for testing the hook.
class HookTracker
  include SelfAgency

  attr_reader :generated_log

  def initialize
    @generated_log = []
  end

  def on_method_generated(method_name, scope, code)
    @generated_log << { method_name: method_name, scope: scope, code: code }
  end
end

def configure_self_agency!
  SelfAgency.configure do |config|
    config.provider = :ollama
    config.model    = "qwen3-coder:30b"
    config.api_base = "http://localhost:11434/v1"
  end
end
