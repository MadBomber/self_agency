# frozen_string_literal: true

module SelfAgency
  class Error < StandardError; end
  class GenerationError < Error; end
  class ValidationError < Error; end
  class SecurityError   < Error; end
end
