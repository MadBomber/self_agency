# frozen_string_literal: true

require "test_helper"

class TestPipeline < Minitest::Test
  def setup
    SelfAgency.reset!
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
  # self_agency_generate alias
  # --------------------------------------------------------------------------

  def test_self_agency_generate_alias_invokes_pipeline
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_alias_add(a, b)\n  a + b\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "A precise spec for adding two numbers"
      when :generate then generated_code
      end
    end

    method_names = obj.self_agency_generate("add two numbers")
    assert_equal [:self_agency_alias_add], method_names
    assert_equal 5, obj.self_agency_alias_add(2, 3)
  ensure
    SampleClass.undef_method(:self_agency_alias_add) if SampleClass.method_defined?(:self_agency_alias_add)
  end

  # --------------------------------------------------------------------------
  # Generation-level retry with error feedback
  # --------------------------------------------------------------------------

  def test_retry_succeeds_after_bad_then_good_code
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    bad_code  = "def self_agency_retry_ok(a, b)\n  a +\nend"
    good_code = "def self_agency_retry_ok(a, b)\n  a + b\nend"
    call_count = 0

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape then "spec"
      when :generate
        call_count += 1
        call_count == 1 ? bad_code : good_code
      end
    end

    method_names = obj._("add two numbers")
    assert_equal [:self_agency_retry_ok], method_names
    assert_equal 5, obj.self_agency_retry_ok(2, 3)
    assert_equal 2, call_count
  ensure
    SampleClass.undef_method(:self_agency_retry_ok) if SampleClass.method_defined?(:self_agency_retry_ok)
  end

  def test_retry_raises_after_exhausting_retries
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    bad_code = "def self_agency_retry_fail(a, b)\n  a +\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then bad_code
      end
    end

    assert_raises(SelfAgency::ValidationError) { obj._("add two numbers") }
  end

  def test_retry_respects_generation_retries_config
    SelfAgency.reset!
    SelfAgency.configure do |config|
      config.provider           = :ollama
      config.model              = "qwen3-coder:30b"
      config.api_base           = "http://localhost:11434/v1"
      config.generation_retries = 3
    end
    obj = SampleClass.new

    bad_code  = "def self_agency_retry_cfg(a, b)\n  a +\nend"
    good_code = "def self_agency_retry_cfg(a, b)\n  a + b\nend"
    call_count = 0

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape then "spec"
      when :generate
        call_count += 1
        call_count < 3 ? bad_code : good_code
      end
    end

    method_names = obj._("add two numbers")
    assert_equal [:self_agency_retry_cfg], method_names
    assert_equal 3, call_count
  ensure
    SampleClass.undef_method(:self_agency_retry_cfg) if SampleClass.method_defined?(:self_agency_retry_cfg)
  end

  def test_retry_passes_error_feedback_to_template
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    bad_code  = "def self_agency_retry_fb(a, b)\n  a +\nend"
    good_code = "def self_agency_retry_fb(a, b)\n  a + b\nend"
    captured_vars = nil

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape then "spec"
      when :generate
        if vars[:previous_error]
          captured_vars = vars
          good_code
        else
          bad_code
        end
      end
    end

    obj._("add two numbers")
    assert_instance_of String, captured_vars[:previous_error]
    assert_includes captured_vars[:previous_error], "syntax error"
    assert_equal bad_code, captured_vars[:previous_code]
  ensure
    SampleClass.undef_method(:self_agency_retry_fb) if SampleClass.method_defined?(:self_agency_retry_fb)
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
end
