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
- **Instance variables** -- So it can use existing state
- **Public methods** -- So it can call or complement existing behavior

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

## Error Handling

`_()` can raise three types of errors:

```ruby
begin
  calc._("a method to do something")
rescue SelfAgency::GenerationError => e
  # LLM returned nil
rescue SelfAgency::ValidationError => e
  # Code is empty, malformed, or has syntax errors
rescue SelfAgency::SecurityError => e
  # Dangerous pattern detected in generated code
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

See [Errors](../api/errors.md) for the full error hierarchy.
