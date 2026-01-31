# frozen_string_literal: true

require "test_helper"

class TestValidator < Minitest::Test
  def setup
    SelfAgency.reset!
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
end
