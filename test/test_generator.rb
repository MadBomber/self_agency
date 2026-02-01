# frozen_string_literal: true

require "test_helper"

class TestGenerator < Minitest::Test
  def setup
    SelfAgency.reset!
  end

  # --------------------------------------------------------------------------
  # self_agency_generation_vars
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
  # self_agency_ask_with_template raises GenerationError on failure
  # --------------------------------------------------------------------------

  def test_ask_with_template_raises_generation_error_on_failure
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    assert_raises(SelfAgency::GenerationError) do
      obj.send(:self_agency_ask_with_template, :nonexistent_template)
    end
  end

  def test_ask_with_template_error_includes_original_message
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    error = assert_raises(SelfAgency::GenerationError) do
      obj.send(:self_agency_ask_with_template, :nonexistent_template)
    end
    assert_match(/LLM request failed/, error.message)
    assert_match(/\(.+: .+\)/, error.message) # includes (ClassName: message)
  end

  def test_ask_with_template_preserves_cause_chain
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    error = assert_raises(SelfAgency::GenerationError) do
      obj.send(:self_agency_ask_with_template, :nonexistent_template)
    end
    refute_nil error.cause, "expected error.cause to be the original exception"
  end

  # --------------------------------------------------------------------------
  # self_agency_shape scope instructions
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
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:self_agency_test_add) if sandbox&.method_defined?(:self_agency_test_add)
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
    sandbox = SampleClass.instance_variable_get(:@self_agency_class_sandbox)
    sandbox.remove_method(:self_agency_test_class_hello) if sandbox&.method_defined?(:self_agency_test_class_hello)
  end

  def test_eval_unknown_scope_raises_validation_error
    obj = SampleClass.new
    code = "def foo\n  42\nend"
    assert_raises(SelfAgency::ValidationError) do
      obj.send(:self_agency_eval, code, :unknown)
    end
  end

  # --------------------------------------------------------------------------
  # Module reuse — only one sandbox module per scope in the ancestor chain
  # --------------------------------------------------------------------------

  def test_eval_instance_scope_reuses_sandbox_module
    obj = SampleClass.new
    obj.send(:self_agency_eval, "def sa_reuse_a\n  1\nend", :instance)
    obj.send(:self_agency_eval, "def sa_reuse_b\n  2\nend", :instance)

    sandbox_modules = SampleClass.ancestors.select do |mod|
      mod.is_a?(Module) && !mod.is_a?(Class) && mod.included_modules.include?(SelfAgency::Sandbox)
    end
    assert_equal 1, sandbox_modules.length, "expected exactly one instance sandbox module in ancestors"
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:sa_reuse_a) if sandbox&.method_defined?(:sa_reuse_a)
    sandbox.remove_method(:sa_reuse_b) if sandbox&.method_defined?(:sa_reuse_b)
  end

  def test_eval_redefine_same_method_takes_latest_body
    obj = SampleClass.new
    obj.send(:self_agency_eval, "def sa_redef\n  'first'\nend", :instance)
    assert_equal "first", SampleClass.new.sa_redef

    obj.send(:self_agency_eval, "def sa_redef\n  'second'\nend", :instance)
    assert_equal "second", SampleClass.new.sa_redef
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:sa_redef) if sandbox&.method_defined?(:sa_redef)
  end

  def test_singleton_sandbox_modules_are_per_instance
    a = SampleClass.new
    b = SampleClass.new

    a.send(:self_agency_eval, "def sa_sing\n  'a'\nend", :singleton)
    b.send(:self_agency_eval, "def sa_sing\n  'b'\nend", :singleton)

    assert_equal "a", a.sa_sing
    assert_equal "b", b.sa_sing

    sandbox_a = a.instance_variable_get(:@self_agency_singleton_sandbox)
    sandbox_b = b.instance_variable_get(:@self_agency_singleton_sandbox)
    refute_same sandbox_a, sandbox_b, "each instance should have its own singleton sandbox module"
  end
end
