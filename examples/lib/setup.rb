require_relative "../../lib/self_agency"

SelfAgency.configure do |config|
  config.provider        = :ollama
  config.model           = "qwen3-coder:30b"
  config.api_base        = "http://localhost:11434/v1"
  config.request_timeout = 120
end
