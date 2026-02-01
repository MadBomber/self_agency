# Errors

SelfAgency defines a hierarchy of errors under `SelfAgency::Error`.

## Hierarchy

```
StandardError
  └── SelfAgency::Error
        ├── SelfAgency::GenerationError
        ├── SelfAgency::ValidationError
        └── SelfAgency::SecurityError
```

All SelfAgency errors inherit from `SelfAgency::Error`, which inherits from `StandardError`. This means you can catch all SelfAgency errors with a single `rescue`:

```ruby
rescue SelfAgency::Error => e
```

---

## `SelfAgency::Error`

Base error class. Also raised directly when configuration is missing.

**Raised when:**

- `_()` is called before `SelfAgency.configure`
- `_save!` is called with no generated methods
- `_save!` is called on an anonymous class

```ruby
SelfAgency.reset!
Widget.new._("a method")
#=> SelfAgency::Error: SelfAgency.configure has not been called
```

---

## `SelfAgency::GenerationError`

Raised when the LLM fails to produce output or when an LLM communication failure occurs.

**Attributes:**

| Attribute | Type | Description |
|-----------|------|-------------|
| `stage` | `Symbol` or `nil` | `:shape` or `:generate` -- which pipeline stage failed |
| `attempt` | `Integer` or `nil` | The attempt number (during retry loop) |

**Raised when:**

- The shape stage returns `nil` -- message: `"Prompt shaping failed (LLM returned nil)"`
- The generate stage returns `nil` -- message: `"Code generation failed (LLM returned nil)"`
- An LLM communication failure occurs -- message: `"LLM request failed (ExceptionClass: details)"`

!!! note
    LLM communication failures (network errors, timeouts, provider API errors) are wrapped and re-raised as `GenerationError`. The original exception class and message are preserved in the error message. If generation consistently fails, verify your LLM provider is running and the configuration (provider, model, api_base) is correct.

```ruby
rescue SelfAgency::GenerationError => e
  puts "LLM failed at #{e.stage} stage: #{e.message}"
end
```

---

## `SelfAgency::ValidationError`

Raised when the generated code fails structural or syntactic validation.

**Attributes:**

| Attribute | Type | Description |
|-----------|------|-------------|
| `generated_code` | `String` or `nil` | The code that failed validation |
| `attempt` | `Integer` or `nil` | The attempt number (during retry loop) |

**Raised when:**

- Generated code is empty after sanitization
- Generated code does not contain a `def...end` structure
- Generated code has a syntax error (`RubyVM::InstructionSequence.compile` fails)

!!! note
    During automatic retries, `ValidationError` is only raised to the caller after all `generation_retries` attempts are exhausted. The `attempt` attribute indicates which attempt produced the final failure.

```ruby
# Empty code
widget.send(:self_agency_validate!, "")
#=> SelfAgency::ValidationError: code is empty

# Missing def...end
widget.send(:self_agency_validate!, "puts 'hello'")
#=> SelfAgency::ValidationError: missing def...end structure

# Syntax error
widget.send(:self_agency_validate!, "def broken\n  if true\nend")
#=> SelfAgency::ValidationError: syntax error: ...
```

---

## `SelfAgency::SecurityError`

Raised when the generated code contains a dangerous pattern.

**Attributes:**

| Attribute | Type | Description |
|-----------|------|-------------|
| `matched_pattern` | `String` or `nil` | The specific pattern text that was matched |
| `generated_code` | `String` or `nil` | The code that triggered the error |

**Raised when:**

- The code matches `SelfAgency::DANGEROUS_PATTERNS` (static analysis)

The error message includes the specific matched pattern, e.g., `"dangerous pattern detected: system"`.

!!! note
    This is `SelfAgency::SecurityError`, distinct from Ruby's built-in `::SecurityError`. The runtime sandbox raises `::SecurityError` (the Ruby built-in), while the static validator raises `SelfAgency::SecurityError`.

```ruby
# System call
widget.send(:self_agency_validate!, "def hack\n  system('ls')\nend")
#=> SelfAgency::SecurityError: dangerous pattern detected: system

# File access
widget.send(:self_agency_validate!, "def hack\n  File.read('/etc/passwd')\nend")
#=> SelfAgency::SecurityError: dangerous pattern detected: File.

# Eval
widget.send(:self_agency_validate!, "def hack\n  eval('1+1')\nend")
#=> SelfAgency::SecurityError: dangerous pattern detected: eval
```

---

## Error Handling Patterns

### Catch All SelfAgency Errors

```ruby
begin
  obj._("a method description")
rescue SelfAgency::Error => e
  puts "#{e.class}: #{e.message}"
end
```

### Catch Specific Errors

```ruby
begin
  obj._("a method description")
rescue SelfAgency::GenerationError => e
  puts "LLM failed at #{e.stage} stage (attempt #{e.attempt}): #{e.message}"
rescue SelfAgency::ValidationError => e
  puts "Validation failed on attempt #{e.attempt}: #{e.message}"
  puts "Code was: #{e.generated_code}" if e.generated_code
rescue SelfAgency::SecurityError => e
  puts "Security: matched '#{e.matched_pattern}' in generated code"
end
```
