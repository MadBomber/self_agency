# Configuration

SelfAgency must be configured before generating any methods. Call `SelfAgency.configure` with a block:

```ruby
SelfAgency.configure do |config|
  config.provider = :ollama
  config.model    = "qwen3-coder:30b"
  config.api_base = "http://localhost:11434/v1"
end
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `provider` | `Symbol` | `:ollama` | RubyLLM provider name |
| `model` | `String` | `"qwen3-coder:30b"` | LLM model identifier |
| `api_base` | `String` | `"http://localhost:11434/v1"` | Provider API endpoint |
| `request_timeout` | `Integer` | `30` | Request timeout in seconds |
| `max_retries` | `Integer` | `1` | Number of retries on failure |
| `retry_interval` | `Float` | `0.5` | Seconds between retries |
| `template_directory` | `String` | `lib/self_agency/prompts` | Path to ERB prompt templates |
| `generation_retries` | `Integer` | `3` | Max retry attempts when validation or security checks fail |
| `logger` | `Proc`, `Logger`, or `nil` | `nil` | Logger for pipeline events (see [Logging](#logging) below) |

## Configuration Is Mandatory

Calling `_()` before `configure` raises `SelfAgency::Error`:

```ruby
SelfAgency.reset!

class Widget
  include SelfAgency
end

Widget.new._("a method")
#=> SelfAgency::Error: SelfAgency.configure has not been called
```

## Applying Configuration

`SelfAgency.configure` delegates to `RubyLLM.configure` and `RubyLLM::Template.configure` under the hood:

- `provider` + `api_base` set the provider-specific API base on RubyLLM. The `api_base` value is assigned to the RubyLLM config key `<provider>_api_base`. For example, `:openai` maps to `openai_api_base`, `:ollama` maps to `ollama_api_base`.
- `request_timeout`, `max_retries`, and `retry_interval` map directly to RubyLLM settings
- `template_directory` is passed to `RubyLLM::Template`

## Resetting Configuration

`SelfAgency.reset!` restores all defaults and marks the gem as unconfigured:

```ruby
SelfAgency.reset!

SelfAgency.ensure_configured!
#=> SelfAgency::Error: SelfAgency.configure has not been called
```

## Checking Configuration

`SelfAgency.ensure_configured!` raises if `configure` has not been called:

```ruby
SelfAgency.ensure_configured!  # raises or succeeds silently
```

## Logging

Set `logger` to observe each stage of the pipeline. It accepts either a callable (receives `stage` and `message`) or a `Logger`-compatible object (uses `.debug`):

```ruby
# Callable logger
SelfAgency.configure do |config|
  config.logger = ->(stage, message) { puts "[#{stage}] #{message}" }
  # ...
end

# Standard library Logger
require "logger"
SelfAgency.configure do |config|
  config.logger = Logger.new($stdout)
  # ...
end
```

Logged stages: `:shape`, `:generate`, `:validate`, `:retry`, `:complete`.

## Example: Custom Timeouts

For complex method generation that takes longer:

```ruby
SelfAgency.configure do |config|
  config.provider        = :ollama
  config.model           = "qwen3-coder:30b"
  config.api_base        = "http://localhost:11434/v1"
  config.request_timeout = 120
  config.max_retries     = 3
  config.retry_interval  = 1.0
end
```

## Example: OpenAI

```ruby
SelfAgency.configure do |config|
  config.provider = :openai
  config.model    = "gpt-4o"
  config.api_base = "https://api.openai.com/v1"
end
```
