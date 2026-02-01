# frozen_string_literal: true

require "ruby_llm"
require "ruby_llm/template"

module SelfAgency
  CONFIG_MUTEX = Mutex.new

  class Configuration
    attr_accessor :provider, :model, :api_base,
                  :request_timeout, :max_retries, :retry_interval,
                  :template_directory, :generation_retries, :logger

    def initialize
      @provider           = :ollama
      @model              = "qwen3-coder:30b"
      @api_base           = "http://localhost:11434/v1"
      @request_timeout    = 30
      @max_retries        = 1
      @retry_interval     = 0.5
      @template_directory = File.join(__dir__, "prompts")
      @generation_retries = 3
      @logger             = nil
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      CONFIG_MUTEX.synchronize do
        yield(configuration)
        apply_ruby_llm_config!
        configuration
      end
    end

    def reset!
      CONFIG_MUTEX.synchronize do
        @configuration = Configuration.new
        @configured = false
      end
    end

    def ensure_configured!
      raise Error, "SelfAgency.configure has not been called" unless @configured
    end

    def included(base)
      base.extend(ClassMethods)
      base.instance_variable_set(:@self_agency_mutex, Mutex.new)
    end

    private

    def apply_ruby_llm_config!
      cfg = configuration
      provider_key = :"#{cfg.provider}_api_base"

      RubyLLM.configure do |c|
        c.public_send(:"#{provider_key}=", cfg.api_base) if c.respond_to?(:"#{provider_key}=")
        c.request_timeout = cfg.request_timeout
        c.max_retries     = cfg.max_retries
        c.retry_interval  = cfg.retry_interval
      end

      RubyLLM::Template.configure do |c|
        c.template_directory = cfg.template_directory
      end

      @configured = true
    end
  end
end
