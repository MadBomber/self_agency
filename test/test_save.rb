# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class TestSave < Minitest::Test
  def setup
    SelfAgency.reset!
  end

  # --------------------------------------------------------------------------
  # _save! — argument validation
  # --------------------------------------------------------------------------

  def test_save_raises_argument_error_for_non_string_or_symbol
    obj = SampleClass.new
    assert_raises(ArgumentError) { obj._save!(as: 123) }
  end

  def test_save_raises_error_when_no_generated_methods
    obj = SampleClass.new
    assert_raises(SelfAgency::Error) { obj._save!(as: "Collector") }
  end

  # --------------------------------------------------------------------------
  # _save! — name conversion helpers
  # --------------------------------------------------------------------------

  def test_to_class_name_from_snake_case_symbol
    obj = SampleClass.new
    assert_equal "Collector", obj.send(:self_agency_to_class_name, :collector)
  end

  def test_to_class_name_from_snake_case_string
    obj = SampleClass.new
    assert_equal "WeatherAnalyst", obj.send(:self_agency_to_class_name, "weather_analyst")
  end

  def test_to_class_name_from_camel_case_string
    obj = SampleClass.new
    assert_equal "WeatherAnalyst", obj.send(:self_agency_to_class_name, "WeatherAnalyst")
  end

  def test_to_snake_case
    obj = SampleClass.new
    assert_equal "weather_analyst", obj.send(:self_agency_to_snake_case, "WeatherAnalyst")
  end

  def test_to_snake_case_single_word
    obj = SampleClass.new
    assert_equal "collector", obj.send(:self_agency_to_snake_case, "Collector")
  end

  # --------------------------------------------------------------------------
  # _save! — file output
  # --------------------------------------------------------------------------

  def test_save_writes_file_with_default_path
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_save_test\n  42\nend"
    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("a test method")

    Dir.mktmpdir do |dir|
      result = obj._save!(as: :collector, path: File.join(dir, "collector.rb"))
      assert File.exist?(result)
      content = File.read(result)
      assert_includes content, "class Collector < SampleClass"
      assert_includes content, "def self_agency_save_test"
    end
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:self_agency_save_test) if sandbox&.method_defined?(:self_agency_save_test)
  end

  def test_save_returns_default_path_from_as
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_save_path\n  1\nend"
    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("a method")

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        result = obj._save!(as: "WeatherAnalyst")
        assert_equal "weather_analyst.rb", result
        assert File.exist?(result)
      end
    end
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:self_agency_save_path) if sandbox&.method_defined?(:self_agency_save_path)
  end

  def test_save_uses_explicit_path
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_save_explicit\n  1\nend"
    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("a method")

    Dir.mktmpdir do |dir|
      custom_path = File.join(dir, "custom_name.rb")
      result = obj._save!(as: :collector, path: custom_path)
      assert_equal custom_path, result
      assert File.exist?(custom_path)
    end
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:self_agency_save_explicit) if sandbox&.method_defined?(:self_agency_save_explicit)
  end

  def test_save_includes_frozen_string_literal
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_save_frozen\n  1\nend"
    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("a method")

    Dir.mktmpdir do |dir|
      obj._save!(as: :collector, path: File.join(dir, "collector.rb"))
      content = File.read(File.join(dir, "collector.rb"))
      assert_includes content, "# frozen_string_literal: true"
    end
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:self_agency_save_frozen) if sandbox&.method_defined?(:self_agency_save_frozen)
  end

  def test_save_includes_require_relative
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_save_req\n  1\nend"
    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("a method")

    Dir.mktmpdir do |dir|
      obj._save!(as: :collector, path: File.join(dir, "collector.rb"))
      content = File.read(File.join(dir, "collector.rb"))
      assert_match(/\Arequire_relative/, content.lines.find { |l| l.include?("require_relative") }.strip)
    end
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:self_agency_save_req) if sandbox&.method_defined?(:self_agency_save_req)
  end

  def test_save_includes_description_as_comment
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_save_desc\n  1\nend"
    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("compute the answer")

    Dir.mktmpdir do |dir|
      obj._save!(as: :collector, path: File.join(dir, "collector.rb"))
      content = File.read(File.join(dir, "collector.rb"))
      assert_includes content, "  # compute the answer"
    end
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:self_agency_save_desc) if sandbox&.method_defined?(:self_agency_save_desc)
  end

  def test_save_indents_method_body
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_save_indent(a, b)\n  a + b\nend"
    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("add numbers")

    Dir.mktmpdir do |dir|
      obj._save!(as: :collector, path: File.join(dir, "collector.rb"))
      content = File.read(File.join(dir, "collector.rb"))
      assert_includes content, "  def self_agency_save_indent(a, b)\n    a + b\n  end"
    end
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:self_agency_save_indent) if sandbox&.method_defined?(:self_agency_save_indent)
  end

  def test_save_multiple_methods
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_save_m1\n  1\nend\n\ndef self_agency_save_m2\n  2\nend"
    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("two methods")

    Dir.mktmpdir do |dir|
      obj._save!(as: :collector, path: File.join(dir, "collector.rb"))
      content = File.read(File.join(dir, "collector.rb"))
      assert_includes content, "  def self_agency_save_m1"
      assert_includes content, "  def self_agency_save_m2"
    end
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:self_agency_save_m1) if sandbox&.method_defined?(:self_agency_save_m1)
    sandbox.remove_method(:self_agency_save_m2) if sandbox&.method_defined?(:self_agency_save_m2)
  end

  def test_save_accepts_string_as_parameter
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_save_str\n  1\nend"
    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("a method")

    Dir.mktmpdir do |dir|
      obj._save!(as: "Collector", path: File.join(dir, "collector.rb"))
      content = File.read(File.join(dir, "collector.rb"))
      assert_includes content, "class Collector < SampleClass"
    end
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:self_agency_save_str) if sandbox&.method_defined?(:self_agency_save_str)
  end

  def test_save_converts_snake_case_to_camel_case_in_class_name
    SelfAgency.reset!
    configure_self_agency!
    obj = SampleClass.new

    generated_code = "def self_agency_save_camel\n  1\nend"
    obj.define_singleton_method(:self_agency_ask_with_template) do |name, **vars|
      case name
      when :shape    then "spec"
      when :generate then generated_code
      end
    end

    obj._("a method")

    Dir.mktmpdir do |dir|
      obj._save!(as: :weather_analyst, path: File.join(dir, "weather_analyst.rb"))
      content = File.read(File.join(dir, "weather_analyst.rb"))
      assert_includes content, "class WeatherAnalyst < SampleClass"
    end
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:self_agency_save_camel) if sandbox&.method_defined?(:self_agency_save_camel)
  end
end
