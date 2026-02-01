# Generating Methods

The `_()` method is the core API of SelfAgency. It takes a natural language description and generates one or more Ruby methods at runtime.

## Single Method

```ruby
names = calc._("an instance method named 'add' that accepts two integer parameters a and b, and returns their sum")
#=> [:add]

calc.add(3, 7)  #=> 10
```

## Multiple Methods

Describe several methods in one call:

```ruby
names = calc._(
  "create four instance methods: " \
  "'add(a, b)' returns a + b, " \
  "'subtract(a, b)' returns a - b, " \
  "'multiply(a, b)' returns a * b, " \
  "'divide(a, b)' returns a.to_f / b (raises ZeroDivisionError if b is zero)"
)
#=> [:add, :subtract, :multiply, :divide]
```

`_()` always returns an Array of Symbol method names, even for a single method.

## Return Value

The return value is always an `Array<Symbol>` containing the names of all methods defined by that call:

```ruby
method_names = calc._("a method to double a number")
method_names        #=> [:double]
method_names.class  #=> Array
```

## Class Context

The LLM receives introspection context about your class when generating methods:

- **Class name** -- So it can reference the correct class
- **Instance variables** -- Current instance variables on the calling object
- **Public methods** -- Methods defined directly on your class (excludes inherited `Object` methods)

This means generated methods can work with your class's existing state:

```ruby
class BankAccount
  include SelfAgency

  attr_reader :owner, :balance

  def initialize(owner, balance)
    @owner   = owner
    @balance = balance
  end
end

account = BankAccount.new("Alice", 1000)
account._(
  "an instance method named 'summary' that returns a string like " \
  "'Account for <owner>: $<balance>' using the @owner and @balance instance variables"
)

account.summary  #=> "Account for Alice: $1000"
```

## Method Overrides

Generating a method with the same name as an existing method overrides it. SelfAgency uses `Module#prepend`, so the generated method takes priority in Ruby's method resolution order (MRO):

```ruby
class Formatter
  include SelfAgency

  def greet(name)
    "Hello, #{name}"
  end
end

fmt = Formatter.new
fmt.greet("World")  #=> "Hello, World"

fmt._(
  "an instance method named 'greet' that accepts a name parameter " \
  "and returns 'Greetings, <name>! Welcome aboard.'"
)

fmt.greet("World")  #=> "Greetings, World! Welcome aboard."
```

## Automatic Retries

When validation or security checks fail, SelfAgency automatically retries code generation. On each retry, the previous error message and failed code are fed back to the LLM so it can self-correct.

The number of attempts is controlled by `generation_retries` (default: `3`):

```ruby
SelfAgency.configure do |config|
  config.generation_retries = 5  # try up to 5 times
  # ...
end
```

If all attempts fail, the last `ValidationError` or `SecurityError` is raised. The error includes an `attempt` attribute indicating which attempt produced it.

!!! note
    Only validation and security failures trigger retries. If the LLM returns `nil` (a `GenerationError`), the error is raised immediately with no retry.

## Error Handling

`_()` can raise three types of errors. Each error class carries additional attributes for programmatic inspection:

```ruby
begin
  calc._("a method to do something")
rescue SelfAgency::GenerationError => e
  e.stage    #=> :shape or :generate
  e.attempt  #=> Integer (attempt number, if during retry)
rescue SelfAgency::ValidationError => e
  e.generated_code  #=> String (the code that failed)
  e.attempt         #=> Integer (attempt number, if during retry)
rescue SelfAgency::SecurityError => e
  e.matched_pattern  #=> String (the pattern that triggered the error)
  e.generated_code   #=> String (the code that failed)
end
```

Or catch all SelfAgency errors at once:

```ruby
begin
  calc._("a method to do something")
rescue SelfAgency::Error => e
  puts "Generation failed: #{e.message}"
end
```

!!! note
    LLM communication failures (network errors, timeouts, API errors) are wrapped and re-raised as `GenerationError` with a message like `"LLM request failed (Faraday::TimeoutError: timeout)"`. The original exception class and message are preserved in the error message. If generation consistently fails, verify your LLM provider is running and reachable.

See [Errors](../api/errors.md) for the full error hierarchy.
