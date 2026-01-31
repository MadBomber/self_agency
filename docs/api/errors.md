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

Raised when the LLM fails to produce output.

**Raised when:**

- The shape stage returns `nil`
- The generate stage returns `nil`

```ruby
rescue SelfAgency::GenerationError => e
  puts "LLM failed: #{e.message}"
end
```

---

## `SelfAgency::ValidationError`

Raised when the generated code fails structural or syntactic validation.

**Raised when:**

- Generated code is empty after sanitization
- Generated code does not contain a `def...end` structure
- Generated code has a syntax error (`RubyVM::InstructionSequence.compile` fails)

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

**Raised when:**

- The code matches `SelfAgency::DANGEROUS_PATTERNS` (static analysis)

!!! note
    This is `SelfAgency::SecurityError`, distinct from Ruby's built-in `::SecurityError`. The runtime sandbox raises `::SecurityError` (the Ruby built-in), while the static validator raises `SelfAgency::SecurityError`.

```ruby
# System call
widget.send(:self_agency_validate!, "def hack\n  system('ls')\nend")
#=> SelfAgency::SecurityError: dangerous pattern detected

# File access
widget.send(:self_agency_validate!, "def hack\n  File.read('/etc/passwd')\nend")
#=> SelfAgency::SecurityError: dangerous pattern detected

# Eval
widget.send(:self_agency_validate!, "def hack\n  eval('1+1')\nend")
#=> SelfAgency::SecurityError: dangerous pattern detected
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
rescue SelfAgency::GenerationError
  puts "LLM did not return a response"
rescue SelfAgency::ValidationError => e
  puts "Code validation failed: #{e.message}"
rescue SelfAgency::SecurityError
  puts "Dangerous code detected"
end
```
