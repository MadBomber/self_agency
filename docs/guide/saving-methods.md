# Saving Methods

`_save!` writes an object's generated methods as a subclass in a Ruby source file. This lets you capture LLM-generated methods as permanent, version-controlled code.

## Basic Usage

```ruby
foo = Foo.new
foo._("an instance method to add two integers")
foo._("an instance method to subtract two integers")

foo._save!(as: :calculator)
```

This writes `calculator.rb`:

```ruby
# frozen_string_literal: true

require_relative "foo"

class Calculator < Foo
  # an instance method to add two integers
  def add(a, b)
    a + b
  end

  # an instance method to subtract two integers
  def subtract(a, b)
    a - b
  end
end
```

## The `as:` Parameter

`as:` is required. It sets the subclass name and (by default) the output filename. It accepts a String or Symbol.

Snake case is automatically converted to CamelCase:

```ruby
foo._save!(as: :weather_analyst)
# Writes weather_analyst.rb with class WeatherAnalyst < Foo

foo._save!(as: "WeatherAnalyst")
# Same result
```

## Custom File Path

Override the default file path with `path:`:

```ruby
foo._save!(as: :calculator, path: "lib/calculator.rb")
```

## Require Path

The generated file includes a `require_relative` pointing back to the parent class source file. The path is computed relative to the output file location.

## Multiple Instances, Different Methods

Each instance of a class can have different generated methods. `_save!` captures only the methods generated on that specific instance:

```ruby
collector = Robot.new(name: "Collector")
analyst   = Robot.new(name: "Analyst")

# Each robot generates different methods via _()
collector._save!(as: collector.name)  # collector.rb with class Collector < Robot
analyst._save!(as: analyst.name)      # analyst.rb   with class Analyst < Robot
```

## Description Comments

Each method in the saved file includes the original natural language description as a comment header, so the intent behind the generated code is preserved.

## Errors

| Error | Condition |
|-------|-----------|
| `ArgumentError` | `as:` is not a String or Symbol |
| `SelfAgency::Error` | No generated methods to save |
| `SelfAgency::Error` | Parent class is anonymous (no name) |
