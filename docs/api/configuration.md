# Configuration

## `SelfAgency::Configuration`

Holds all configuration options. Created automatically by `SelfAgency.configure`.

### Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `provider` | `Symbol` | `:ollama` | RubyLLM provider name |
| `model` | `String` | `"qwen3-coder:30b"` | LLM model identifier |
| `api_base` | `String` | `"http://localhost:11434/v1"` | Provider API endpoint |
| `request_timeout` | `Integer` | `30` | Request timeout in seconds |
| `max_retries` | `Integer` | `1` | Number of retries on failure |
| `retry_interval` | `Float` | `0.5` | Seconds between retries |
| `template_directory` | `String` | `lib/self_agency/prompts` | Path to ERB prompt templates |
| `generation_retries` | `Integer` | `3` | Max retry attempts when validation or security checks fail |
| `logger` | `Proc`, `Logger`, or `nil` | `nil` | Logger for pipeline events (callable or Logger-compatible) |

All attributes are read/write via `attr_accessor`.

---

## Module-Level Methods

### `SelfAgency.configure { |config| ... }`

Configure SelfAgency. Yields a `Configuration` instance.

Internally calls `RubyLLM.configure` and `RubyLLM::Template.configure` with the corresponding settings, then marks the gem as configured.

**Returns:** `Configuration`

```ruby
SelfAgency.configure do |config|
  config.provider        = :ollama
  config.model           = "qwen3-coder:30b"
  config.api_base        = "http://localhost:11434/v1"
  config.request_timeout = 60
end
```

---

### `SelfAgency.configuration`

Access the current configuration instance. Creates a default instance if none exists.

**Returns:** `Configuration`

```ruby
cfg = SelfAgency.configuration
cfg.model  #=> "qwen3-coder:30b"
```

---

### `SelfAgency.reset!`

Restore all configuration to defaults and mark the gem as unconfigured. Subsequent calls to `_()` will raise until `configure` is called again.

```ruby
SelfAgency.reset!
```

---

### `SelfAgency.ensure_configured!`

Raise `SelfAgency::Error` if `configure` has not been called.

**Raises:** `SelfAgency::Error` with message `"SelfAgency.configure has not been called"`

```ruby
SelfAgency.ensure_configured!
```

---

### `SelfAgency.included(base)`

Hook called when a class includes `SelfAgency`. Extends the including class with `SelfAgency::ClassMethods` and initializes a per-class mutex for thread-safe pipeline execution.

This is called automatically by Ruby's `include` mechanism; you do not need to call it directly.
