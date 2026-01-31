# Scopes

SelfAgency supports three scopes for generated methods: `:instance`, `:singleton`, and `:class`. The scope is passed as the `scope:` keyword argument to `_()`.

## Instance Scope (Default)

Instance methods are available on **all instances** of the class. This is the default scope.

```ruby
class Greeter
  include SelfAgency
end

alice = Greeter.new
bob   = Greeter.new

alice._("an instance method named 'hello' that returns the string 'Hello, world!'")

alice.hello  #=> "Hello, world!"
bob.hello    #=> "Hello, world!" -- available to all instances
```

Internally, SelfAgency creates an anonymous module containing the generated method and uses `prepend` to add it to the class. This means the method appears on all current and future instances.

## Singleton Scope

Singleton methods are available on **only one specific instance**. Other instances of the same class do not have the method.

```ruby
alice._("a method named 'secret' that returns 'Alice only'", scope: :singleton)

alice.secret                    #=> "Alice only"
bob.respond_to?(:secret)       #=> false
```

Internally, singleton-scoped methods are prepended to the instance's singleton class.

## Class Scope

Class methods are available on the **class itself**, not on instances.

```ruby
alice._("a class method named 'self.class_greeting' that returns 'Greetings from Greeter'", scope: :class)

Greeter.class_greeting  #=> "Greetings from Greeter"
```

!!! note
    For class methods, the LLM generates `def self.method_name`. SelfAgency strips the `self.` prefix before evaluating, since it prepends the method to the class's singleton class.

## Scope Comparison

| Scope | Keyword | Available On | Mechanism |
|-------|---------|-------------|-----------|
| Instance | `scope: :instance` | All instances of the class | `self.class.prepend(module)` |
| Singleton | `scope: :singleton` | One specific instance | `singleton_class.prepend(module)` |
| Class | `scope: :class` | The class itself | `self.class.singleton_class.prepend(module)` |

## Combining Scopes

You can mix scopes freely on the same class:

```ruby
calc = StatisticsCalculator.new([10, 20, 30])

# Instance methods -- available to all instances
calc._("an instance method named 'mean' ...")

# Class method -- available on StatisticsCalculator itself
calc._("a class method named 'self.from_range' ...", scope: :class)

# Singleton method -- available only on this calc instance
calc._("a method named 'report' ...", scope: :singleton)
```
