# Installation

## Requirements

- Ruby >= 3.2.0
- An LLM provider (Ollama recommended for local development)

## Add to Your Project

Add SelfAgency to your Gemfile:

```ruby
gem "self_agency"
```

Then install:

```bash
bundle install
```

Or install directly:

```bash
gem install self_agency
```

## Dependencies

SelfAgency depends on:

| Gem | Purpose |
|-----|---------|
| `ruby_llm` | LLM provider communication |
| `ruby_llm-template` | ERB prompt template management |
| `method_source` | Source code retrieval for file-defined methods |

These are installed automatically when you install the gem.

## LLM Provider Setup

SelfAgency uses [ruby_llm](https://github.com/crmne/ruby_llm) under the hood, which supports multiple providers. The default configuration targets a local Ollama instance.

### Ollama (Default)

Install Ollama and pull a model:

```bash
# Install Ollama (macOS)
brew install ollama

# Start the server
ollama serve

# Pull a model
ollama pull qwen3-coder:30b
```

### Other Providers

Any provider supported by ruby_llm works. Set the `provider`, `model`, and `api_base` in your configuration:

```ruby
SelfAgency.configure do |config|
  config.provider = :openai
  config.model    = "gpt-4o"
  config.api_base = "https://api.openai.com/v1"
end
```

See [Configuration](../guide/configuration.md) for all options.
