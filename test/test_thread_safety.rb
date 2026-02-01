# frozen_string_literal: true

require "test_helper"

class TestThreadSafety < Minitest::Test
  def setup
    SelfAgency.reset!
  end

  # --------------------------------------------------------------------------
  # Per-class mutex
  # --------------------------------------------------------------------------

  def test_class_has_mutex_after_include
    assert_instance_of Mutex, SampleClass.self_agency_mutex
  end

  def test_each_including_class_gets_its_own_mutex
    refute_same SampleClass.self_agency_mutex, HookTracker.self_agency_mutex
  end

  # --------------------------------------------------------------------------
  # Concurrent _() pipeline via self_agency_eval
  # --------------------------------------------------------------------------

  def test_concurrent_eval_defines_both_methods
    barrier = Queue.new

    t1 = Thread.new do
      barrier.pop
      obj = SampleClass.new
      SampleClass.self_agency_mutex.synchronize do
        obj.send(:self_agency_eval, "def sa_thread_a\n  'a'\nend", :instance)
      end
    end

    t2 = Thread.new do
      barrier.pop
      obj = SampleClass.new
      SampleClass.self_agency_mutex.synchronize do
        obj.send(:self_agency_eval, "def sa_thread_b\n  'b'\nend", :instance)
      end
    end

    barrier << :go
    barrier << :go
    t1.join
    t2.join

    assert_equal "a", SampleClass.new.sa_thread_a
    assert_equal "b", SampleClass.new.sa_thread_b
  ensure
    sandbox = SampleClass.instance_variable_get(:@self_agency_instance_sandbox)
    sandbox.remove_method(:sa_thread_a) if sandbox&.method_defined?(:sa_thread_a)
    sandbox.remove_method(:sa_thread_b) if sandbox&.method_defined?(:sa_thread_b)
  end

  # --------------------------------------------------------------------------
  # Concurrent configure / reset!
  # --------------------------------------------------------------------------

  def test_concurrent_configure_and_reset_do_not_raise
    threads = 10.times.map do |i|
      Thread.new do
        if i.even?
          SelfAgency.configure { |c| c.model = "model-#{i}" }
        else
          SelfAgency.reset!
        end
      end
    end

    threads.each(&:join)
    # No exception means success
  end
end
