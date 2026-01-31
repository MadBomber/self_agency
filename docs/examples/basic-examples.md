# Basic Examples (01--09)

These examples cover SelfAgency's core features one at a time.

## 01: Basic Usage

The simplest example: include `SelfAgency`, generate a single method, call it.

```ruby
class Calculator
  include SelfAgency
end

calc = Calculator.new
method_names = calc._("an instance method named 'add' that accepts two integer parameters a and b, and returns their sum")

puts method_names.inspect  #=> [:add]
puts calc.add(3, 7)        #=> 10
```

**Source:** `examples/01_basic_usage.rb`

---

## 02: Multiple Methods

Generate several related methods in a single `_()` call.

```ruby
class Arithmetic
  include SelfAgency
end

arith = Arithmetic.new
method_names = arith._(
  "create four instance methods: " \
  "'add(a, b)' returns a + b, " \
  "'subtract(a, b)' returns a - b, " \
  "'multiply(a, b)' returns a * b, " \
  "'divide(a, b)' returns a.to_f / b (raises ZeroDivisionError if b is zero)"
)

puts method_names.inspect  #=> [:add, :subtract, :multiply, :divide]
puts arith.multiply(10, 3) #=> 30
```

**Source:** `examples/02_multiple_methods.rb`

---

## 03: Scopes

Demonstrates all three scopes: instance, singleton, and class.

```ruby
class Greeter
  include SelfAgency
end

alice = Greeter.new
bob   = Greeter.new

# Instance -- available to all instances
alice._("an instance method named 'hello' that returns 'Hello, world!'")
bob.hello  #=> "Hello, world!"

# Singleton -- available to one instance only
alice._("a method named 'secret' that returns 'Alice only'", scope: :singleton)
alice.secret                 #=> "Alice only"
bob.respond_to?(:secret)     #=> false

# Class -- available on the class itself
alice._("a class method named 'self.class_greeting' that returns 'Greetings from Greeter'", scope: :class)
Greeter.class_greeting       #=> "Greetings from Greeter"
```

**Source:** `examples/03_scopes.rb`

---

## 04: Source Inspection

View generated source code and the fallback to `method_source` for file-defined methods.

```ruby
class MathHelper
  include SelfAgency

  # Multiplies a number by two.
  def double(n)
    n * 2
  end
end

helper = MathHelper.new
helper._("an instance method named 'square' that accepts an integer n and returns n * n")

# LLM-generated method (includes description as comment header)
puts helper._source_for(:square)

# File-defined method (falls back to method_source gem)
puts helper._source_for(:double)

# Unknown method
helper._source_for(:nonexistent)  #=> nil
```

**Source:** `examples/04_source_inspection.rb`

---

## 05: Lifecycle Hook

Override `on_method_generated` to log or persist each generated method.

```ruby
class PersistentCalculator
  include SelfAgency

  attr_reader :generation_log

  def initialize
    @generation_log = []
  end

  def on_method_generated(method_name, scope, code)
    @generation_log << { method_name: method_name, scope: scope, code: code }
    puts "[hook] Generated :#{method_name} (scope: #{scope})"
  end
end

calc = PersistentCalculator.new
calc._("an instance method named 'increment' that returns n + 1")
# [hook] Generated :increment (scope: instance)
```

**Source:** `examples/05_lifecycle_hook.rb`

---

## 06: Configuration

Explores all configuration options. Runs offline (no LLM required).

Demonstrates:

- Default values before `configure`
- `ensure_configured!` raises before `configure`
- Setting custom values
- `reset!` restores defaults
- Custom `template_directory`

**Source:** `examples/06_configuration.rb`

---

## 07: Error Handling

Exercises the error hierarchy. Runs offline (no LLM required).

Demonstrates:

- `SelfAgency::Error` hierarchy verification
- Calling `_()` before `configure` raises `Error`
- `ValidationError` for empty code, missing `def...end`, syntax errors
- `SecurityError` for `system`, `File`, `eval`, `require` patterns
- Catching all errors with `rescue SelfAgency::Error`

**Source:** `examples/07_error_handling.rb`

---

## 08: Class Context

Shows how the LLM receives class introspection (class name, instance variables, public methods) to generate context-aware code.

```ruby
class BankAccount
  include SelfAgency

  attr_reader :owner, :balance

  def initialize(owner, balance)
    @owner   = owner
    @balance = balance
  end

  def deposit(amount)
    @balance += amount
  end
end

account = BankAccount.new("Alice", 1000)
account._(
  "an instance method named 'summary' that returns 'Account for <owner>: $<balance>'"
)

puts account.summary  #=> "Account for Alice: $1000"
```

**Source:** `examples/08_class_context.rb`

---

## 09: Method Override

Demonstrates that generating a method with the same name as an existing method overrides it via `Module#prepend`.

```ruby
class Formatter
  include SelfAgency

  def greet(name)
    "Hello, #{name}"
  end
end

fmt = Formatter.new
puts fmt.greet("World")  #=> "Hello, World"

fmt._(
  "an instance method named 'greet' that returns 'Greetings, <name>! Welcome aboard.'"
)

puts fmt.greet("World")  #=> "Greetings, World! Welcome aboard."
```

The MRO shows the prepended module:

```
0. #<Module:0x...>  ← anonymous module with generated method
1. Formatter
2. SelfAgency
3. ...
```

**Source:** `examples/09_method_override.rb`
