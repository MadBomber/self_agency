# frozen_string_literal: true

module SelfAgency
  class Error < StandardError; end

  class GenerationError < Error
    attr_reader :stage, :attempt

    def initialize(message = nil, stage: nil, attempt: nil)
      @stage   = stage
      @attempt = attempt
      super(message)
    end
  end

  class ValidationError < Error
    attr_reader :generated_code, :attempt

    def initialize(message = nil, generated_code: nil, attempt: nil)
      @generated_code = generated_code
      @attempt        = attempt
      super(message)
    end
  end

  class SecurityError < Error
    attr_reader :matched_pattern, :generated_code

    def initialize(message = nil, matched_pattern: nil, generated_code: nil)
      @matched_pattern = matched_pattern
      @generated_code  = generated_code
      super(message)
    end
  end
end
