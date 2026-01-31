# frozen_string_literal: true

require "test_helper"

class TestSandbox < Minitest::Test
  def setup
    SelfAgency.reset!
  end

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
end
