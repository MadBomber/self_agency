> [!CAUTION]
> This is an experiment. It may not be fit for any specific purpose.

<div align="center">
  <h1>SelfAgency</h1>
  <p><strong>LLM-powered runtime method generation for Ruby classes.</strong></p>
</div>

<br/>

<table>
  <tr>
    <td width="50%" valign="top">
      <img src="docs/assets/images/self_agency.gif" alt="SelfAgency Demo" width="100%">
      <br/>
      <strong><a href="https://madbomber.github.io/self_agency">Documentation</a></strong>
    </td>
    <td width="50%" valign="top">
      <h3>Key Features</h3>
      <ul>
        <li><strong>Natural language to Ruby methods</strong> — describe what you want, get working code</li>
        <li><strong>Multiple methods at once</strong> — generate related methods in a single call</li>
        <li><strong>Three scopes</strong> — instance, singleton, and class methods</li>
        <li><strong>Two-stage LLM pipeline</strong> — shape the prompt, then generate code</li>
        <li><strong>Security by default</strong> — static analysis + runtime sandbox</li>
        <li><strong>Source inspection</strong> — view generated code with <code>_source_for</code></li>
        <li><strong>Save to files</strong> — persist as subclasses with <code>_save!</code></li>
        <li><strong>Provider agnostic</strong> — any LLM via <a href="https://github.com/crmne/ruby_llm">ruby_llm</a></li>
      </ul>
    </td>
  </tr>
</table>

<br/>

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

### Saving generated methods to a file

`_save!` writes the object's generated methods as a subclass in a Ruby source file:

```ruby
foo._("an instance method to add two integers")
foo._("an instance method to subtract two integers")

foo._save!(as: :calculator)
# Writes calculator.rb:
#   require_relative "foo"
#
#   class Calculator < Foo
#     def add(a, b)
#       a + b
#     end
#
#     def subtract(a, b)
#       a - b
#     end
#   end
```

`as:` is required. It accepts a String or Symbol. Snake case is converted to CamelCase for the class name:

```ruby
foo._save!(as: :weather_analyst)  # → class WeatherAnalyst < Foo in weather_analyst.rb
foo._save!(as: "WeatherAnalyst")  # → same result
```

Override the default file path with `path:`:

```ruby
foo._save!(as: :calculator, path: "lib/calculator.rb")
```

This is especially useful when multiple instances of the same class have different generated methods. Each instance saves as a distinct subclass:

```ruby
collector = Robot.new(name: "Collector", ...)
analyst   = Robot.new(name: "Analyst", ...)

collector._save!(as: collector.name)  # → collector.rb with class Collector < Robot
analyst._save!(as: analyst.name)      # → analyst.rb   with class Analyst < Robot
```

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
