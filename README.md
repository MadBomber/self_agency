# SelfAgency

LLM-powered runtime method generation for Ruby classes. Describe what you want in plain English, get working methods back.

## Installation

Add to your Gemfile:

```ruby
gem "self_agency"
```

Then run:

```bash
bundle install
```

## Usage

```ruby
require "self_agency"

SelfAgency.configure do |config|
  config.provider = :ollama
  config.model    = "qwen3-coder:30b"
  config.api_base = "http://localhost:11434/v1"
end

class Foo
  include SelfAgency
end

foo = Foo.new
```

### Generate a single method

```ruby
names = foo._("an instance method to add two integers, return the result")
#=> [:add]
foo.add(1, 1) #=> 2
```

### Generate multiple methods at once

```ruby
names = foo._("create add, subtract, multiply, and divide methods for two integers")
#=> [:add, :subtract, :multiply, :divide]
foo.subtract(5, 3) #=> 2
```

`_` always returns an Array of method name Symbols.

### Scopes

**Instance method** (default) -- available on all instances:

```ruby
foo._("a method to double a number")
```

**Singleton method** -- available on one instance only:

```ruby
foo._("a method called greet that returns 'hello'", scope: :singleton)
foo.greet #=> "hello"
```

**Class method**:

```ruby
foo._("a class method called ping that returns 'pong'", scope: :class)
Foo.ping #=> "pong"
```

Generated methods override existing methods with the same name.

### Viewing generated source

`_source_for` returns the source code for any method, with the original description as a comment header for LLM-generated methods:

```ruby
foo._("add two integers and return the result")
puts foo._source_for(:add)
# >> # add two integers and return the result
# >> def add(a, b)
# >>   a + b
# >> end
```

Works at the class level too:

```ruby
puts Foo._source_for(:add)
```

For methods defined in files, `_source_for` falls back to `method_source` and includes any comments above the method definition:

```ruby
puts foo._source_for(:file_defined_method)
# >> # Adds two numbers together.
# >> def file_defined_method(a, b)
# >>   a + b
# >> end
```

Returns `nil` if the method doesn't exist or its source is unavailable.

### Lifecycle hook

Override `on_method_generated` to persist or log generated methods. It is called once per method:

```ruby
class Foo
  include SelfAgency

  def on_method_generated(method_name, scope, code)
    File.write("generated/#{method_name}.rb", code)
  end
end
```

## Configuration

| Option | Default | Description |
|---|---|---|
| `provider` | `:ollama` | RubyLLM provider |
| `model` | `"qwen3-coder:30b"` | LLM model name |
| `api_base` | `"http://localhost:11434/v1"` | Provider API endpoint |
| `request_timeout` | `30` | Timeout in seconds |
| `max_retries` | `1` | Number of retries |
| `retry_interval` | `0.5` | Seconds between retries |
| `template_directory` | `lib/self_agency/prompts` | Path to ERB prompt templates |

### Prompt templates

SelfAgency uses [ruby_llm-template](https://github.com/danielfriis/ruby_llm-template) for prompt management. Templates live in the configured `template_directory`:

```
prompts/
  shape/
    system.txt.erb    # Rewrites casual descriptions into precise specs
    user.txt.erb      # Provides class context and user request
  generate/
    system.txt.erb    # Instructs the LLM to produce Ruby code
    user.txt.erb      # Passes the shaped spec
```

Override `template_directory` to customize prompts:

```ruby
SelfAgency.configure do |config|
  config.template_directory = "/path/to/my/prompts"
  # ...
end
```

## Architecture

The gem uses a two-stage LLM pipeline:

1. **Shape** -- Rewrites the user's casual English into a precise Ruby method specification
2. **Generate** -- Produces `def...end` blocks from the shaped spec

Generated code then passes through:

- **Sanitization** -- Strips markdown fences and `<think>` blocks
- **Validation** -- Checks for empty code, missing `def...end`, syntax errors, and dangerous patterns
- **Sandboxed eval** -- Code is evaluated inside an anonymous module that shadows dangerous Kernel methods

## Security

Generated code is validated and sandboxed:

- **Static analysis** rejects code containing `system`, `exec`, `File`, `IO`, `Kernel`, `eval`, `require`, and other dangerous patterns
- **Runtime sandbox** shadows `system`, `exec`, `spawn`, `fork`, backticks, and `open` with methods that raise `SecurityError`

## Errors

| Exception | Meaning |
|---|---|
| `SelfAgency::GenerationError` | LLM returned nil |
| `SelfAgency::ValidationError` | Code is empty, malformed, or has syntax errors |
| `SelfAgency::SecurityError` | Dangerous pattern detected in generated code |

## Development

```bash
bin/setup
rake test
```

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
