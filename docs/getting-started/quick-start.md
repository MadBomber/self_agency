# Quick Start

This guide walks through a complete example from configuration to using generated methods.

## 1. Configure SelfAgency

Before generating any methods, call `SelfAgency.configure`:

```ruby
require "self_agency"

SelfAgency.configure do |config|
  config.provider = :ollama
  config.model    = "qwen3-coder:30b"
  config.api_base = "http://localhost:11434/v1"
end
```

Configuration is mandatory. Calling `_()` before `configure` raises `SelfAgency::Error`.

## 2. Include the Module

Add `include SelfAgency` to any class:

```ruby
class Calculator
  include SelfAgency
end

calc = Calculator.new
```

## 3. Generate a Method

Call `_()` with a natural language description:

```ruby
names = calc._("an instance method named 'add' that accepts two integer parameters a and b, and returns their sum")
#=> [:add]
```

`_()` always returns an Array of Symbol method names.

## 4. Use the Method

The generated method is available immediately:

```ruby
calc.add(3, 7)   #=> 10
calc.add(-1, 1)  #=> 0
```

Instance methods (the default scope) are available on all instances of the class:

```ruby
other = Calculator.new
other.add(100, 200)  #=> 300
```

## 5. View the Source

Inspect what the LLM generated:

```ruby
puts calc._source_for(:add)
# >> # an instance method named 'add' that accepts two integer
# >> # parameters a and b, and returns their sum
# >> def add(a, b)
# >>   a + b
# >> end
```

## 6. Generate Multiple Methods

A single `_()` call can produce several methods:

```ruby
names = calc._(
  "create add, subtract, multiply, and divide methods for two integers"
)
#=> [:add, :subtract, :multiply, :divide]

calc.subtract(10, 3)  #=> 7
calc.multiply(4, 5)   #=> 20
calc.divide(10, 3)    #=> 3.333...
```

## Next Steps

- [How to Use SelfAgency](../guide/how-to-use.md) -- Where SelfAgency fits in your design workflow
- [Scopes](../guide/scopes.md) -- Generate singleton and class methods
- [Source Inspection](../guide/source-inspection.md) -- View and retrieve generated source
- [Saving Methods](../guide/saving-methods.md) -- Persist generated methods to files
- [Configuration](../guide/configuration.md) -- All configuration options
