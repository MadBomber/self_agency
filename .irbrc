require_relative 'lib/self_agency'

SelfAgency.configure do |config|
  config.provider = :ollama
  config.model    = "qwen3-coder:30b"
  config.api_base = "http://localhost:11434/v1"
end

class Foo
  include SelfAgency

  # The original correcy implementation
  def add(a, b)
    a + b
  end
end

class Bar < Foo
end

FOO = Foo.new
BAR = Bar.new
