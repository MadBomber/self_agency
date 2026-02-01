# frozen_string_literal: true

require "test_helper"

class TestConfiguration < Minitest::Test
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
    assert_equal 3, cfg.generation_retries
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
end
