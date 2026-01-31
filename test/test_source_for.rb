# frozen_string_literal: true

require "test_helper"

class TestSourceFor < Minitest::Test
  def setup
    SelfAgency.reset!
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
end
