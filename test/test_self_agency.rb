# frozen_string_literal: true

require "test_helper"
require "debug_me"
include DebugMe

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

# ============================================================================
# Helpers — configure once for tests that need it, stub LLM calls
# ============================================================================

def configure_self_agency!
  SelfAgency.configure do |config|
    config.provider = :ollama
    config.model    = "qwen3-coder:30b"
    config.api_base = "http://localhost:11434/v1"
  end
end

# ============================================================================
# Tests
# ============================================================================

class TestSelfAgency < Minitest::Test
  def setup
    SelfAgency.reset!
  end

  # --------------------------------------------------------------------------
  # Version
  # --------------------------------------------------------------------------

  def test_that_it_has_a_version_number
    refute_nil ::SelfAgency::VERSION
  end

  # --------------------------------------------------------------------------
  # Error hierarchy
  # --------------------------------------------------------------------------

  def test_error_inherits_from_standard_error
    assert SelfAgency::Error < StandardError
  end

  def test_generation_error_inherits_from_error
    assert SelfAgency::GenerationError < SelfAgency::Error
  end

  def test_validation_error_inherits_from_error
    assert SelfAgency::ValidationError < SelfAgency::Error
  end

  def test_security_error_inherits_from_error
    assert SelfAgency::SecurityError < SelfAgency::Error
  end

  # --------------------------------------------------------------------------
  # Configuration — defaults
  # --------------------------------------------------------------------------

  def test_configuration_defaults
    SelfAgency.reset!
    cfg = SelfAgency.configuration
    assert_equal :ollama, cfg.provider
    assert_equal "qwen3-coder:30b", cfg.model
    assert_equal "http://localhost:11434/v1", cfg.api_base
    assert_equal 30, cfg.request_timeout
    assert_equal 1, cfg.max_retries
    assert_equal 0.5, cfg.retry_interval
  end

  def test_configuration_default_template_directory
    SelfAgency.reset!
    cfg = SelfAgency.configuration
    expected = File.join(File.dirname(File.expand_path("../../lib/self_agency/configuration.rb", __FILE__)), "lib", "self_agency", "prompts")
    assert cfg.template_directory.end_with?("lib/self_agency/prompts"),
      "Expected template_directory to end with lib/self_agency/prompts, got: #{cfg.template_directory}"
    assert Dir.exist?(cfg.template_directory),
      "Default template_directory should exist on disk"
  end

  def test_configure_block
    SelfAgency.reset!
    SelfAgency.configure do |config|
      config.provider = :ollama
      config.model    = "qwen3-coder:30b"
      config.api_base = "http://localhost:11434/v1"
    end
    cfg = SelfAgency.configuration
    assert_equal :ollama, cfg.provider
    assert_equal "qwen3-coder:30b", cfg.model
  end

  def test_configure_custom_template_directory
    SelfAgency.reset!
    custom_dir = "/tmp/my_prompts"
    SelfAgency.configure do |config|
      config.provider           = :ollama
      config.model              = "qwen3-coder:30b"
      config.api_base           = "http://localhost:11434/v1"
      config.template_directory = custom_dir
    end
    assert_equal custom_dir, SelfAgency.configuration.template_directory
  end

  def test_configure_sets_ruby_llm_template_directory
    SelfAgency.reset!
    SelfAgency.configure do |config|
      config.provider = :ollama
      config.model    = "qwen3-coder:30b"
      config.api_base = "http://localhost:11434/v1"
    end
    expected = SelfAgency.configuration.template_directory
    assert_equal expected, RubyLLM::Template.configuration.template_directory
  end

  # --------------------------------------------------------------------------
  # Configuration — ensure_configured! / reset!
  # --------------------------------------------------------------------------

  def test_ensure_configured_raises_before_configure
    SelfAgency.reset!
    assert_raises(SelfAgency::Error) { SelfAgency.ensure_configured! }
  end

  def test_ensure_configured_passes_after_configure
    SelfAgency.reset!
    configure_self_agency!
    SelfAgency.ensure_configured! # should not raise
  end

  def test_reset_clears_configured_state
    SelfAgency.reset!
    configure_self_agency!
    SelfAgency.ensure_configured! # passes
    SelfAgency.reset!
    assert_raises(SelfAgency::Error) { SelfAgency.ensure_configured! }
  end

  def test_reset_creates_fresh_configuration
    SelfAgency.reset!
    SelfAgency.configure do |config|
      config.provider = :openai
      config.model    = "gpt-4"
      config.api_base = "https://api.openai.com/v1"
    end
    assert_equal :openai, SelfAgency.configuration.provider
    SelfAgency.reset!
    assert_equal :ollama, SelfAgency.configuration.provider
  end

  # --------------------------------------------------------------------------
  # Validation — rejects bad code
  # --------------------------------------------------------------------------

  def test_validation_rejects_empty_code
    obj = SampleClass.new
    assert_raises(SelfAgency::ValidationError) do
      obj.send(:self_agency_validate!, "")
    end
  end

  def test_validation_rejects_missing_def
    obj = SampleClass.new
    assert_raises(SelfAgency::ValidationError) do
      obj.send(:self_agency_validate!, "puts 'hello'")
    end
  end

  def test_validation_rejects_syntax_errors
    obj = SampleClass.new
    assert_raises(SelfAgency::ValidationError) do
      obj.send(:self_agency_validate!, "def broken\n  if true\nend")
    end
  end

  def test_validation_rejects_dangerous_patterns
    obj = SampleClass.new
    dangerous_snippets = [
      "def hack\n  system('ls')\nend",
      "def hack\n  exec('ls')\nend",
      "def hack\n  File.read('/etc/passwd')\nend",
      "def hack\n  IO.popen('ls')\nend",
      "def hack\n  Kernel.exit\nend",
      "def hack\n  require 'socket'\nend",
      "def hack\n  eval('1+1')\nend",
    ]

    dangerous_snippets.each do |code|
      assert_raises(SelfAgency::SecurityError, "Expected SecurityError for: #{code}") do
        obj.send(:self_agency_validate!, code)
      end
    end
  end

  def test_validation_rejects_spawn
    obj = SampleClass.new
    assert_raises(SelfAgency::SecurityError) do
      obj.send(:self_agency_validate!, "def hack\n  spawn('ls')\nend")
    end
  end

  def test_validation_rejects_fork
    obj = SampleClass.new
    assert_raises(SelfAgency::SecurityError) do
      obj.send(:self_agency_validate!, "def hack\n  fork { puts 1 }\nend")
    end
  end

  def test_validation_rejects_abort
    obj = SampleClass.new
    assert_raises(SelfAgency::SecurityError) do
      obj.send(:self_agency_validate!, "def hack\n  abort('bye')\nend")
    end
  end

  def test_validation_rejects_exit
    obj = SampleClass.new
    assert_raises(SelfAgency::SecurityError) do
      obj.send(:self_agency_validate!, "def hack\n  exit(1)\nend")
    end
  end

  def test_validation_rejects_backticks
    obj = SampleClass.new
    assert_raises(SelfAgency::SecurityError) do
      obj.send(:self_agency_validate!, "def hack\n  `ls`\nend")
    end
  end

  def test_validation_rejects_percent_x_braces
    obj = SampleClass.new
    assert_raises(SelfAgency::SecurityError) do
      obj.send(:self_agency_validate!, "def hack\n  %x{ls}\nend")
    end
  end

  def test_validation_rejects_percent_x_brackets
    obj = SampleClass.new
    assert_raises(SelfAgency::SecurityError) do
      obj.send(:self_agency_validate!, "def hack\n  %x[ls]\nend")
    end
  end

  def test_validation_rejects_percent_x_parens
    obj = SampleClass.new
    assert_raises(SelfAgency::SecurityError) do
      obj.send(:self_agency_validate!, "def hack\n  %x(ls)\nend")
    end
  end

  def test_validation_rejects_open3
    obj = SampleClass.new
    assert_raises(SelfAgency::SecurityError) do
      obj.send(:self_agency_validate!, "def hack\n  Open3.capture2('ls')\nend")
    end
  end

  def test_validation_rejects_process
    obj = SampleClass.new
    assert_raises(SelfAgency::SecurityError) do
      obj.send(:self_agency_validate!, "def hack\n  Process.kill('TERM', pid)\nend")
    end
  end

  def test_validation_rejects_load
    obj = SampleClass.new
    assert_raises(SelfAgency::SecurityError) do
      obj.send(:self_agency_validate!, "def hack\n  load 'evil.rb'\nend")
    end
  end

  def test_validation_rejects___send__
    obj = SampleClass.new
    assert_raises(SelfAgency::SecurityError) do
      obj.send(:self_agency_validate!, "def hack\n  obj.__send__(:secret)\nend")
    end
  end

  def test_validation_rejects_remove_method
    obj = SampleClass.new
    assert_raises(SelfAgency::SecurityError) do
      obj.send(:self_agency_validate!, "def hack\n  remove_method :foo\nend")
    end
  end

  def test_validation_rejects_undef_method
    obj = SampleClass.new
    assert_raises(SelfAgency::SecurityError) do
      obj.send(:self_agency_validate!, "def hack\n  undef_method :foo\nend")
    end
  end

  def test_validation_rejects_send_without_parens
    obj = SampleClass.new
    assert_raises(SelfAgency::SecurityError) do
      obj.send(:self_agency_validate!, "def hack\n  send :secret\nend")
    end
  end

  # --------------------------------------------------------------------------
  # Validation — accepts good code
  # --------------------------------------------------------------------------

  def test_validation_accepts_clean_code
    obj = SampleClass.new
    clean = "def add(a, b)\n  a + b\nend"
    obj.send(:self_agency_validate!, clean) # should not raise
  end

  def test_validation_accepts_send_with_parens
    obj = SampleClass.new
    # send( with parens is allowed per the negative lookahead in DANGEROUS_PATTERNS
    code = "def safe\n  [1,2,3].send(:length)\nend"
    obj.send(:self_agency_validate!, code) # should not raise
  end

  def test_validation_accepts_question_mark_method
    obj = SampleClass.new
    code = "def empty?\n  true\nend"
    obj.send(:self_agency_validate!, code) # should not raise
  end

  def test_validation_accepts_bang_method
    obj = SampleClass.new
    code = "def save!\n  true\nend"
    obj.send(:self_agency_validate!, code) # should not raise
  end

  # --------------------------------------------------------------------------
  # Sanitize
  # --------------------------------------------------------------------------

  def test_sanitize_strips_markdown_fences
    obj = SampleClass.new
    raw = "```ruby\ndef foo\n  42\nend\n```"
    result = obj.send(:self_agency_sanitize, raw)
    assert_equal "def foo\n  42\nend", result
  end

  def test_sanitize_strips_plain_fences
    obj = SampleClass.new
    raw = "```\ndef foo\n  42\nend\n```"
    result = obj.send(:self_agency_sanitize, raw)
    assert_equal "def foo\n  42\nend", result
  end

  def test_sanitize_strips_think_blocks
    obj = SampleClass.new
    raw = "<think>some reasoning</think>\ndef foo\n  42\nend"
    result = obj.send(:self_agency_sanitize, raw)
    assert_equal "def foo\n  42\nend", result
  end

  def test_sanitize_strips_multiple_think_blocks
    obj = SampleClass.new
    raw = "<think>first thought</think>\ndef foo\n<think>second thought</think>\n  42\nend"
    result = obj.send(:self_agency_sanitize, raw)
    assert_equal "def foo\n\n  42\nend", result
  end

  def test_sanitize_handles_nil_input
    obj = SampleClass.new
    result = obj.send(:self_agency_sanitize, nil)
    assert_equal "", result
  end

  def test_sanitize_strips_leading_trailing_whitespace
    obj = SampleClass.new
    raw = "   \n  def foo\n    42\n  end  \n  "
    result = obj.send(:self_agency_sanitize, raw)
    assert_equal "def foo\n    42\n  end", result
  end

  # --------------------------------------------------------------------------
  # Sandbox
  # --------------------------------------------------------------------------

  def test_sandbox_blocks_system
    obj = SampleClass.new
    mod = Module.new { include SelfAgency::Sandbox }
    obj.singleton_class.include(mod)
    assert_raises(::SecurityError) { obj.send(:system, "ls") }
  end

  def test_sandbox_blocks_exec
    obj = SampleClass.new
    mod = Module.new { include SelfAgency::Sandbox }
    obj.singleton_class.include(mod)
    assert_raises(::SecurityError) { obj.send(:exec, "ls") }
  end

  def test_sandbox_blocks_spawn
    obj = SampleClass.new
    mod = Module.new { include SelfAgency::Sandbox }
    obj.singleton_class.include(mod)
    assert_raises(::SecurityError) { obj.send(:spawn, "ls") }
  end

  def test_sandbox_blocks_fork
    obj = SampleClass.new
    mod = Module.new { include SelfAgency::Sandbox }
    obj.singleton_class.include(mod)
    assert_raises(::SecurityError) { obj.send(:fork) }
  end

  def test_sandbox_blocks_open
    obj = SampleClass.new
    mod = Module.new { include SelfAgency::Sandbox }
    obj.singleton_class.include(mod)
    assert_raises(::SecurityError) { obj.send(:open, "/etc/passwd") }
  end

  # --------------------------------------------------------------------------
  # Generator — self_agency_generation_vars
  # --------------------------------------------------------------------------

  def test_generation_vars_returns_hash_with_class_name
    obj = SampleClass.new
    vars = obj.send(:self_agency_generation_vars)
    assert_equal "SampleClass", vars[:class_name]
  end

  def test_generation_vars_returns_hash_with_ivars
    obj = SampleClass.new
    obj.instance_variable_set(:@x, 1)
    obj.instance_variable_set(:@y, 2)
    vars = obj.send(:self_agency_generation_vars)
    assert_includes vars[:ivars], "@x"
    assert_includes vars[:ivars], "@y"
  end

  def test_generation_vars_returns_hash_with_methods
    obj = SampleClass.new
    vars = obj.send(:self_agency_generation_vars)
    assert_kind_of String, vars[:methods]
  end

  def test_generation_vars_keys
    obj = SampleClass.new
    vars = obj.send(:self_agency_generation_vars)
    assert_equal %i[class_name ivars methods].sort, vars.keys.sort
  end

  # --------------------------------------------------------------------------
  # Generator — self_agency_ask_with_template returns nil on error
  # --------------------------------------------------------------------------

  def test_ask_with_template_returns_nil_on_error
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    # RubyLLM.chat will fail because no real LLM is running; the rescue => e
    # in self_agency_ask_with_template should catch it and return nil.
    result = obj.send(:self_agency_ask_with_template, :nonexistent_template)
    assert_nil result
  end

  # --------------------------------------------------------------------------
  # Generator — self_agency_shape scope instructions
  # --------------------------------------------------------------------------

  def test_shape_calls_template_with_instance_scope
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    captured_vars = nil
    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      captured_vars = vars
      "shaped spec"
    end

    obj.send(:self_agency_shape, "add two numbers", :instance)
    assert_equal "SampleClass", captured_vars[:class_name]
    assert_equal "add two numbers", captured_vars[:raw_prompt]
    assert_match(/instance method/, captured_vars[:scope_instruction])
  end

  def test_shape_calls_template_with_singleton_scope
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    captured_vars = nil
    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      captured_vars = vars
      "shaped spec"
    end

    obj.send(:self_agency_shape, "add two numbers", :singleton)
    assert_match(/singleton method/, captured_vars[:scope_instruction])
  end

  def test_shape_calls_template_with_class_scope
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    captured_vars = nil
    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      captured_vars = vars
      "shaped spec"
    end

    obj.send(:self_agency_shape, "add two numbers", :class)
    assert_match(/class method/, captured_vars[:scope_instruction])
  end

  # --------------------------------------------------------------------------
  # self_agency_eval — scopes
  # --------------------------------------------------------------------------

  def test_eval_instance_scope_defines_instance_method
    obj = SampleClass.new
    code = "def self_agency_test_add(a, b)\n  a + b\nend"
    obj.send(:self_agency_eval, code, :instance)
    # Method should be available on another instance of the same class
    other = SampleClass.new
    assert_equal 3, other.self_agency_test_add(1, 2)
  ensure
    SampleClass.undef_method(:self_agency_test_add) if SampleClass.method_defined?(:self_agency_test_add)
  end

  def test_eval_singleton_scope_defines_singleton_method
    obj = SampleClass.new
    code = "def self_agency_test_greet\n  'hello'\nend"
    obj.send(:self_agency_eval, code, :singleton)
    assert_equal "hello", obj.self_agency_test_greet
    # Other instances should NOT have the method
    other = SampleClass.new
    refute other.respond_to?(:self_agency_test_greet)
  end

  def test_eval_class_scope_defines_class_method
    obj = SampleClass.new
    code = "def self_agency_test_class_hello\n  'world'\nend"
    obj.send(:self_agency_eval, code, :class)
    assert_equal "world", SampleClass.self_agency_test_class_hello
  ensure
    if SampleClass.singleton_class.method_defined?(:self_agency_test_class_hello)
      SampleClass.singleton_class.undef_method(:self_agency_test_class_hello)
    end
  end

  def test_eval_unknown_scope_raises_validation_error
    obj = SampleClass.new
    code = "def foo\n  42\nend"
    assert_raises(SelfAgency::ValidationError) do
      obj.send(:self_agency_eval, code, :unknown)
    end
  end

  # --------------------------------------------------------------------------
  # Full _() pipeline — stubbed LLM
  # --------------------------------------------------------------------------

  def test_underscore_raises_without_configure
    SelfAgency.reset!
    obj = SampleClass.new
    assert_raises(SelfAgency::Error) { obj._("a method") }
  end

  def test_underscore_raises_generation_error_when_shape_returns_nil
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    obj.define_singleton_method(:self_agency_shape) { |_desc, _scope| nil }

    assert_raises(SelfAgency::GenerationError) do
      obj._("a method that does something")
    end
  end

  def test_underscore_raises_generation_error_when_generate_returns_nil
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    call_count = 0
    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      call_count += 1
      if name == :shape
        "a shaped specification"
      else
        nil
      end
    end

    assert_raises(SelfAgency::GenerationError) do
      obj._("a method that does something")
    end
  end

  def test_underscore_full_pipeline_instance_scope
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_pipeline_add(a, b)\n  a + b\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "A precise spec for adding two numbers"
      when :generate then generated_code
      end
    end

    method_names = obj._("add two numbers")
    assert_equal [:self_agency_pipeline_add], method_names
    assert_equal 5, obj.self_agency_pipeline_add(2, 3)
  ensure
    SampleClass.undef_method(:self_agency_pipeline_add) if SampleClass.method_defined?(:self_agency_pipeline_add)
  end

  def test_underscore_full_pipeline_singleton_scope
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_pipeline_greet\n  'hi'\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "A precise spec for greeting"
      when :generate then generated_code
      end
    end

    method_names = obj._("greet", scope: :singleton)
    assert_equal [:self_agency_pipeline_greet], method_names
    assert_equal "hi", obj.self_agency_pipeline_greet

    other = SampleClass.new
    refute other.respond_to?(:self_agency_pipeline_greet)
  end

  def test_underscore_full_pipeline_class_scope
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self.self_agency_pipeline_class_hello\n  'world'\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "A precise spec for class hello"
      when :generate then generated_code
      end
    end

    method_names = obj._("class hello", scope: :class)
    assert_equal [:self_agency_pipeline_class_hello], method_names
    assert_equal "world", SampleClass.self_agency_pipeline_class_hello
  ensure
    if SampleClass.singleton_class.method_defined?(:self_agency_pipeline_class_hello)
      SampleClass.singleton_class.undef_method(:self_agency_pipeline_class_hello)
    end
  end

  # --------------------------------------------------------------------------
  # on_method_generated hook
  # --------------------------------------------------------------------------

  def test_on_method_generated_default_is_noop
    obj = SampleClass.new
    # Should not raise
    obj.on_method_generated(:foo, :instance, "def foo; end")
  end

  def test_on_method_generated_hook_is_called
    SelfAgency.reset!
    configure_self_agency!
    obj = HookTracker.new

    generated_code = "def self_agency_hook_test\n  99\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("hook test method")

    assert_equal 1, obj.generated_log.length
    entry = obj.generated_log.first
    assert_equal :self_agency_hook_test, entry[:method_name]
    assert_equal :instance, entry[:scope]
    assert_equal generated_code, entry[:code]
  ensure
    HookTracker.undef_method(:self_agency_hook_test) if HookTracker.method_defined?(:self_agency_hook_test)
  end

  # --------------------------------------------------------------------------
  # Multiple methods from a single _() call
  # --------------------------------------------------------------------------

  def test_underscore_returns_multiple_method_names
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_multi_a\n  1\nend\n\ndef self_agency_multi_b\n  2\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    names = obj._("two methods")
    assert_equal [:self_agency_multi_a, :self_agency_multi_b], names
    assert_equal 1, obj.self_agency_multi_a
    assert_equal 2, obj.self_agency_multi_b
  ensure
    SampleClass.undef_method(:self_agency_multi_a) if SampleClass.method_defined?(:self_agency_multi_a)
    SampleClass.undef_method(:self_agency_multi_b) if SampleClass.method_defined?(:self_agency_multi_b)
  end

  def test_underscore_stores_individual_source_for_each_method
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_ind_a\n  1\nend\n\ndef self_agency_ind_b\n  2\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("two methods")
    assert_includes obj._source_for(:self_agency_ind_a), "def self_agency_ind_a"
    refute_includes obj._source_for(:self_agency_ind_a), "def self_agency_ind_b"
    assert_includes obj._source_for(:self_agency_ind_b), "def self_agency_ind_b"
    refute_includes obj._source_for(:self_agency_ind_b), "def self_agency_ind_a"
  ensure
    SampleClass.undef_method(:self_agency_ind_a) if SampleClass.method_defined?(:self_agency_ind_a)
    SampleClass.undef_method(:self_agency_ind_b) if SampleClass.method_defined?(:self_agency_ind_b)
  end

  def test_underscore_calls_hook_for_each_method
    SelfAgency.reset!
    configure_self_agency!
    obj = HookTracker.new

    generated_code = "def self_agency_hook_a\n  1\nend\n\ndef self_agency_hook_b\n  2\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("two hook methods")
    assert_equal 2, obj.generated_log.length
    assert_equal :self_agency_hook_a, obj.generated_log[0][:method_name]
    assert_equal :self_agency_hook_b, obj.generated_log[1][:method_name]
  ensure
    HookTracker.undef_method(:self_agency_hook_a) if HookTracker.method_defined?(:self_agency_hook_a)
    HookTracker.undef_method(:self_agency_hook_b) if HookTracker.method_defined?(:self_agency_hook_b)
  end

  # --------------------------------------------------------------------------
  # _source_for — returns generated source code
  # --------------------------------------------------------------------------

  def test_source_returns_nil_for_unknown_method
    obj = SampleClass.new
    assert_nil obj._source_for(:nonexistent)
  end

  def test_source_returns_code_after_generation
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_src_test(a, b)\n  a + b\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("add two numbers")
    result = obj._source_for(:self_agency_src_test)
    assert_equal "# add two numbers\n#{generated_code}", result
  ensure
    SampleClass.undef_method(:self_agency_src_test) if SampleClass.method_defined?(:self_agency_src_test)
  end

  def test_source_accepts_string_argument
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_src_str(x)\n  x * 2\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("double a number")
    result = obj._source_for("self_agency_src_str")
    assert_equal "# double a number\n#{generated_code}", result
  ensure
    SampleClass.undef_method(:self_agency_src_str) if SampleClass.method_defined?(:self_agency_src_str)
  end

  def test_source_tracks_multiple_methods
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    code_a = "def self_agency_src_a\n  1\nend"
    code_b = "def self_agency_src_b\n  2\nend"
    call_count = 0

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape then "spec"
      when :generate
        call_count += 1
        call_count == 1 ? code_a : code_b
      end
    end

    obj._("first method")
    obj._("second method")
    assert_equal "# first method\n#{code_a}", obj._source_for(:self_agency_src_a)
    assert_equal "# second method\n#{code_b}", obj._source_for(:self_agency_src_b)
  ensure
    SampleClass.undef_method(:self_agency_src_a) if SampleClass.method_defined?(:self_agency_src_a)
    SampleClass.undef_method(:self_agency_src_b) if SampleClass.method_defined?(:self_agency_src_b)
  end

  def test_source_includes_multiline_description_as_comment
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_src_multi\n  true\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("add two numbers\nand return the result")
    expected = "# add two numbers\n# and return the result\n#{generated_code}"
    assert_equal expected, obj._source_for(:self_agency_src_multi)
  ensure
    SampleClass.undef_method(:self_agency_src_multi) if SampleClass.method_defined?(:self_agency_src_multi)
  end

  # --------------------------------------------------------------------------
  # _source_for — class-level access
  # --------------------------------------------------------------------------

  def test_class_source_for_returns_nil_for_unknown_method
    assert_nil SampleClass._source_for(:nonexistent)
  end

  def test_class_source_for_returns_code_after_generation
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_cls_src_test\n  42\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("a method")
    assert_equal "# a method\n#{generated_code}", SampleClass._source_for(:self_agency_cls_src_test)
  ensure
    SampleClass.undef_method(:self_agency_cls_src_test) if SampleClass.method_defined?(:self_agency_cls_src_test)
  end

  def test_class_source_for_accepts_string_argument
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_cls_str\n  99\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("a method")
    assert_equal "# a method\n#{generated_code}", SampleClass._source_for("self_agency_cls_str")
  ensure
    SampleClass.undef_method(:self_agency_cls_str) if SampleClass.method_defined?(:self_agency_cls_str)
  end

  # --------------------------------------------------------------------------
  # _source_for — fallback to method_source for file-defined methods
  # --------------------------------------------------------------------------

  def test_instance_source_for_falls_back_to_method_source
    obj = SampleClass.new
    source = obj._source_for(:file_defined_method)
    assert_includes source, "def file_defined_method"
    assert_includes source, '"from file"'
  end

  def test_class_source_for_falls_back_to_method_source
    source = SampleClass._source_for(:file_defined_method)
    assert_includes source, "def file_defined_method"
    assert_includes source, '"from file"'
  end

  def test_instance_source_for_includes_comments
    obj = SampleClass.new
    source = obj._source_for(:commented_method)
    assert_includes source, "# Adds two numbers together."
    assert_includes source, "# Returns the sum."
    assert_includes source, "def commented_method(a, b)"
  end

  def test_class_source_for_includes_comments
    source = SampleClass._source_for(:commented_method)
    assert_includes source, "# Adds two numbers together."
    assert_includes source, "# Returns the sum."
    assert_includes source, "def commented_method(a, b)"
  end

  def test_instance_source_for_returns_nil_for_nonexistent_method
    obj = SampleClass.new
    assert_nil obj._source_for(:totally_nonexistent)
  end

  def test_class_source_for_returns_nil_for_nonexistent_method
    assert_nil SampleClass._source_for(:totally_nonexistent)
  end

  # --------------------------------------------------------------------------
  # Template files exist on disk
  # --------------------------------------------------------------------------

  def test_shape_system_template_exists
    path = File.join(SelfAgency.configuration.template_directory, "shape", "system.txt.erb")
    assert File.exist?(path), "shape/system.txt.erb should exist at #{path}"
  end

  def test_shape_user_template_exists
    path = File.join(SelfAgency.configuration.template_directory, "shape", "user.txt.erb")
    assert File.exist?(path), "shape/user.txt.erb should exist at #{path}"
  end

  def test_generate_system_template_exists
    path = File.join(SelfAgency.configuration.template_directory, "generate", "system.txt.erb")
    assert File.exist?(path), "generate/system.txt.erb should exist at #{path}"
  end

  def test_generate_user_template_exists
    path = File.join(SelfAgency.configuration.template_directory, "generate", "user.txt.erb")
    assert File.exist?(path), "generate/user.txt.erb should exist at #{path}"
  end

  # --------------------------------------------------------------------------
  # Template content sanity checks
  # --------------------------------------------------------------------------

  def test_shape_system_template_contains_prompt_engineer
    path = File.join(SelfAgency.configuration.template_directory, "shape", "system.txt.erb")
    content = File.read(path)
    assert_match(/prompt engineer/i, content)
  end

  def test_shape_user_template_contains_erb_variables
    path = File.join(SelfAgency.configuration.template_directory, "shape", "user.txt.erb")
    content = File.read(path)
    %w[class_name ivars methods scope_instruction raw_prompt].each do |var|
      assert_match(/<%=.*#{var}.*%>/, content, "shape/user.txt.erb should reference #{var}")
    end
  end

  def test_generate_system_template_contains_erb_variables
    path = File.join(SelfAgency.configuration.template_directory, "generate", "system.txt.erb")
    content = File.read(path)
    %w[class_name ivars methods].each do |var|
      assert_match(/<%=.*#{var}.*%>/, content, "generate/system.txt.erb should reference #{var}")
    end
  end

  def test_generate_user_template_contains_shaped_spec
    path = File.join(SelfAgency.configuration.template_directory, "generate", "user.txt.erb")
    content = File.read(path)
    assert_match(/<%=.*shaped_spec.*%>/, content)
  end
end
