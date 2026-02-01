# frozen_string_literal: true

require "test_helper"

class TestDiagnostics < Minitest::Test
  def setup
    SelfAgency.reset!
  end

  # --------------------------------------------------------------------------
  # 4A: Structured Error Context — Error attributes
  # --------------------------------------------------------------------------

  def test_generation_error_accepts_stage_and_attempt
    err = SelfAgency::GenerationError.new("failed", stage: :shape, attempt: 2)
    assert_equal "failed", err.message
    assert_equal :shape, err.stage
    assert_equal 2, err.attempt
  end

  def test_generation_error_defaults_to_nil_attributes
    err = SelfAgency::GenerationError.new("failed")
    assert_nil err.stage
    assert_nil err.attempt
  end

  def test_generation_error_backward_compatible_with_raise
    err = assert_raises(SelfAgency::GenerationError) { raise SelfAgency::GenerationError, "boom" }
    assert_equal "boom", err.message
    assert_nil err.stage
    assert_nil err.attempt
  end

  def test_validation_error_accepts_generated_code_and_attempt
    err = SelfAgency::ValidationError.new("bad code", generated_code: "def x; end", attempt: 3)
    assert_equal "bad code", err.message
    assert_equal "def x; end", err.generated_code
    assert_equal 3, err.attempt
  end

  def test_validation_error_defaults_to_nil_attributes
    err = SelfAgency::ValidationError.new("bad code")
    assert_nil err.generated_code
    assert_nil err.attempt
  end

  def test_validation_error_backward_compatible_with_raise
    err = assert_raises(SelfAgency::ValidationError) { raise SelfAgency::ValidationError, "boom" }
    assert_equal "boom", err.message
    assert_nil err.generated_code
    assert_nil err.attempt
  end

  def test_security_error_accepts_matched_pattern_and_generated_code
    err = SelfAgency::SecurityError.new("danger", matched_pattern: "system", generated_code: "def x; system('ls'); end")
    assert_equal "danger", err.message
    assert_equal "system", err.matched_pattern
    assert_equal "def x; system('ls'); end", err.generated_code
  end

  def test_security_error_defaults_to_nil_attributes
    err = SelfAgency::SecurityError.new("danger")
    assert_nil err.matched_pattern
    assert_nil err.generated_code
  end

  def test_security_error_backward_compatible_with_raise
    err = assert_raises(SelfAgency::SecurityError) { raise SelfAgency::SecurityError, "boom" }
    assert_equal "boom", err.message
    assert_nil err.matched_pattern
    assert_nil err.generated_code
  end

  # --------------------------------------------------------------------------
  # 4A: Validator populates error attributes
  # --------------------------------------------------------------------------

  def test_validate_empty_code_includes_generated_code
    obj = SampleClass.new
    err = assert_raises(SelfAgency::ValidationError) { obj.send(:self_agency_validate!, "") }
    assert_equal "", err.generated_code
  end

  def test_validate_missing_def_includes_generated_code
    obj = SampleClass.new
    code = "puts 'hello'"
    err = assert_raises(SelfAgency::ValidationError) { obj.send(:self_agency_validate!, code) }
    assert_equal code, err.generated_code
  end

  def test_validate_syntax_error_includes_generated_code
    obj = SampleClass.new
    code = "def broken\n  if true\nend"
    err = assert_raises(SelfAgency::ValidationError) { obj.send(:self_agency_validate!, code) }
    assert_equal code, err.generated_code
  end

  def test_validate_dangerous_pattern_includes_matched_pattern
    obj = SampleClass.new
    code = "def hack\n  system('ls')\nend"
    err = assert_raises(SelfAgency::SecurityError) { obj.send(:self_agency_validate!, code) }
    assert_equal "system", err.matched_pattern
    assert_equal code, err.generated_code
  end

  def test_validate_dangerous_pattern_file_includes_matched_pattern
    obj = SampleClass.new
    code = "def hack\n  File.read('/etc/passwd')\nend"
    err = assert_raises(SelfAgency::SecurityError) { obj.send(:self_agency_validate!, code) }
    assert_equal "File.", err.matched_pattern
    assert_equal code, err.generated_code
  end

  # --------------------------------------------------------------------------
  # 4A: Pipeline populates error attributes
  # --------------------------------------------------------------------------

  def test_shape_failure_has_stage
    configure_self_agency!
    obj = SampleClass.new
    obj.define_singleton_method(:self_agency_shape) { |_desc, _scope| nil }

    err = assert_raises(SelfAgency::GenerationError) { obj._("a method") }
    assert_equal :shape, err.stage
  end

  def test_generate_nil_failure_has_stage_and_attempt
    configure_self_agency!
    obj = SampleClass.new

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      name == :shape ? "spec" : nil
    end

    err = assert_raises(SelfAgency::GenerationError) { obj._("a method") }
    assert_equal :generate, err.stage
    assert_equal 1, err.attempt
  end

  def test_validation_failure_after_retries_has_attempt
    configure_self_agency!
    obj = SampleClass.new
    bad_code = "def retry_diag(a, b)\n  a +\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      name == :shape ? "spec" : bad_code
    end

    err = assert_raises(SelfAgency::ValidationError) { obj._("add two numbers") }
    assert_equal 3, err.attempt
    assert_equal bad_code, err.generated_code
  end

  def test_security_failure_after_retries_has_matched_pattern
    configure_self_agency!
    obj = SampleClass.new
    bad_code = "def retry_sec\n  system('ls')\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      name == :shape ? "spec" : bad_code
    end

    err = assert_raises(SelfAgency::SecurityError) { obj._("a method") }
    assert_equal "system", err.matched_pattern
    assert_equal bad_code, err.generated_code
  end

  # --------------------------------------------------------------------------
  # 4B: Configurable Logging Hook
  # --------------------------------------------------------------------------

  def test_logger_defaults_to_nil
    assert_nil SelfAgency.configuration.logger
  end

  def test_logger_is_configurable
    configure_self_agency!
    logger = ->(_stage, _msg) {}
    SelfAgency.configuration.logger = logger
    assert_equal logger, SelfAgency.configuration.logger
  end

  def test_logger_reset_clears_logger
    configure_self_agency!
    SelfAgency.configuration.logger = ->(_stage, _msg) {}
    SelfAgency.reset!
    assert_nil SelfAgency.configuration.logger
  end

  def test_callable_logger_receives_stage_and_message
    configure_self_agency!
    log_entries = []
    SelfAgency.configuration.logger = ->(stage, msg) { log_entries << [stage, msg] }

    obj = SampleClass.new
    generated_code = "def self_agency_log_test\n  42\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      name == :shape ? "spec" : generated_code
    end

    obj._("log test method")

    stages = log_entries.map(&:first)
    assert_includes stages, :shape
    assert_includes stages, :generate
    assert_includes stages, :validate
    assert_includes stages, :complete
    assert log_entries.all? { |_stage, msg| msg.is_a?(String) }
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:self_agency_log_test) if sandbox&.method_defined?(:self_agency_log_test)
  end

  def test_logger_compatible_object_receives_debug_calls
    configure_self_agency!
    debug_messages = []
    fake_logger = Object.new
    fake_logger.define_singleton_method(:debug) { |msg| debug_messages << msg }

    SelfAgency.configuration.logger = fake_logger

    obj = SampleClass.new
    generated_code = "def self_agency_log_obj_test\n  42\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      name == :shape ? "spec" : generated_code
    end

    obj._("log object test")

    refute_empty debug_messages
    assert debug_messages.all? { |msg| msg.match?(/\[SelfAgency:\w+\]/) }
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:self_agency_log_obj_test) if sandbox&.method_defined?(:self_agency_log_obj_test)
  end

  def test_nil_logger_does_not_raise
    configure_self_agency!
    SelfAgency.configuration.logger = nil

    obj = SampleClass.new
    generated_code = "def self_agency_no_log_test\n  42\nend"

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      name == :shape ? "spec" : generated_code
    end

    # Should not raise
    obj._("no log test")
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:self_agency_no_log_test) if sandbox&.method_defined?(:self_agency_no_log_test)
  end

  def test_logger_captures_retry_events
    SelfAgency.configure do |config|
      config.provider           = :ollama
      config.model              = "qwen3-coder:30b"
      config.api_base           = "http://localhost:11434/v1"
      config.generation_retries = 3
    end

    log_entries = []
    SelfAgency.configuration.logger = ->(stage, msg) { log_entries << [stage, msg] }

    obj = SampleClass.new
    bad_code  = "def self_agency_retry_log(a)\n  a +\nend"
    good_code = "def self_agency_retry_log(a)\n  a + 1\nend"
    call_count = 0

    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape then "spec"
      when :generate
        call_count += 1
        call_count == 1 ? bad_code : good_code
      end
    end

    obj._("retry log test")

    stages = log_entries.map(&:first)
    assert_includes stages, :retry
    assert_includes stages, :validate
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:self_agency_retry_log) if sandbox&.method_defined?(:self_agency_retry_log)
  end
end
