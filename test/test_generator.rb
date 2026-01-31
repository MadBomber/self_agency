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
  # self_agency_ask_with_template returns nil on error
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
end
