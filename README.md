<div align="center">
  <h1>SelfAgency</h1>
  Describe what you want in plain language, get working methods back.<br/>
  SelfAgency is a mixin module that gives any Ruby class the ability to<br/>
  generate and install methods at runtime via an LLM.<br/>
  <br/>
  <img src="docs/assets/images/self_agency.gif" alt="SelfAgency Demo" width="100%">
  <br/><br/>
  <a href="https://madbomber.github.io/self_agency"><img src="https://img.shields.io/badge/📖_Full_Documentation-madbomber.github.io/self__agency-7C3AED?style=for-the-badge&labelColor=1a1a2e" alt="Full Documentation"></a>
  <br/><br/>
  <h2>Key Features</h2>
</div>

<table>
  <tr>
    <td width="50%" valign="top">
      <ul>
        <li><strong>Natural language to Ruby methods</strong> — describe what you want, get working code</li>
        <li><strong>Multiple methods at once</strong> — generate related methods in a single call</li>
        <li><strong>Three scopes</strong> — instance, singleton, and class methods</li>
        <li><strong>Two-stage LLM pipeline</strong> — shape the prompt, then generate code</li>
      </ul>
    </td>
    <td width="50%" valign="top">
      <ul>
        <li><strong>Security by default</strong> — 26 static patterns + runtime sandbox</li>
        <li><strong>Automatic retries</strong> — self-corrects on validation failure</li>
        <li><strong>Source inspection &amp; versioning</strong> — view code and track history</li>
        <li><strong>Provider agnostic</strong> — any LLM via <a href="https://github.com/crmne/ruby_llm">ruby_llm</a></li>
      </ul>
    </td>
  </tr>
</table>

> [!CAUTION]
> This is an experiment. It may not be fit for any specific purpose.  Its micro-prompting.  Instead of asking Claude Code, CodeX or Gemini to create an entire application, you can use SelfAgency to generate individual methods.  So far the experiments are showing good success with methods that perform math stuff on its input.

## Installation

Add to your Gemfile:

```ruby
gem "self_agency"
```

Then run `bundle install`. See the [Installation guide](https://madbomber.github.io/self_agency/getting-started/installation/) for LLM provider setup and requirements.

## Quick Start

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
foo._("an instance method to add two integers, return the result")
#=> [:add]
foo.add(1, 1) #=> 2
```

See the [Quick Start walkthrough](https://madbomber.github.io/self_agency/getting-started/quick-start/) for a complete step-by-step guide.

## How to Use

SelfAgency is a Bottom-Up experimentation tool. Start in IRB, describe the behavior you need in plain language, test it with real inputs, inspect the generated source, and refine until the logic is right. Once your methods are proven, save them and wire them into your larger architecture.

```
Describe  →  Generate  →  Test  →  Inspect  →  Refine
    ↑                                              │
    └──────────────────────────────────────────────┘
```

Read [How to Use SelfAgency](https://madbomber.github.io/self_agency/guide/how-to-use/) for a deeper discussion of Top-Down vs. Bottom-Up design and where SelfAgency fits in your workflow.

## Features at a Glance

### Generate multiple methods at once

```ruby
names = foo._("create add, subtract, multiply, and divide methods for two integers")
#=> [:add, :subtract, :multiply, :divide]
```

`_()` always returns an Array of Symbol method names. [Full details →](https://madbomber.github.io/self_agency/guide/generating-methods/)

### Scopes

Generate instance methods (default), singleton methods, or class methods:

```ruby
foo._("a method called greet that returns 'hello'", scope: :singleton)
foo._("a class method called ping that returns 'pong'", scope: :class)
```

[Full details →](https://madbomber.github.io/self_agency/guide/scopes/)

### Source inspection and version history

View the generated source and track changes across regenerations:

```ruby
puts foo._source_for(:add)
versions = Foo._source_versions_for(:add)
```

[Full details →](https://madbomber.github.io/self_agency/guide/source-inspection/)

### Save generated methods to a file

Persist proven methods as a subclass in a Ruby source file:

```ruby
foo._save!(as: :calculator)
# Writes calculator.rb with class Calculator < Foo
```

[Full details →](https://madbomber.github.io/self_agency/guide/saving-methods/)

### Lifecycle hooks

Override `on_method_generated` to persist or log each generated method:

```ruby
def on_method_generated(method_name, scope, code)
  File.write("generated/#{method_name}.rb", code)
end
```

[Full details →](https://madbomber.github.io/self_agency/guide/lifecycle-hooks/)

### Configuration

```ruby
SelfAgency.configure do |config|
  config.provider           = :ollama
  config.model              = "qwen3-coder:30b"
  config.generation_retries = 3
  config.logger             = Logger.new($stdout)
end
```

[All options →](https://madbomber.github.io/self_agency/guide/configuration/) · [Prompt templates →](https://madbomber.github.io/self_agency/guide/prompt-templates/)

## Architecture

A two-stage LLM pipeline: **Shape** rewrites casual English into a precise spec, then **Generate** produces `def...end` blocks. Code passes through sanitization, validation, an optional retry loop, and sandboxed eval. Thread-safe via per-class mutex.

[Full architecture overview →](https://madbomber.github.io/self_agency/architecture/overview/) · [Security model →](https://madbomber.github.io/self_agency/architecture/security/)

## Errors

| Exception | Meaning |
|---|---|
| `SelfAgency::GenerationError` | LLM returned nil or communication failed |
| `SelfAgency::ValidationError` | Code is empty, malformed, or has syntax errors |
| `SelfAgency::SecurityError` | Dangerous pattern detected in generated code |

[Full error reference →](https://madbomber.github.io/self_agency/api/errors/)

## Development

```bash
bin/setup
rake test
```

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
