# Lifecycle Hooks

SelfAgency provides a lifecycle hook that fires each time a method is generated. Override it in your class to persist, log, or react to generated methods.

## `on_method_generated`

```ruby
def on_method_generated(method_name, scope, code)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `method_name` | `Symbol` | Name of the generated method |
| `scope` | `Symbol` | `:instance`, `:singleton`, or `:class` |
| `code` | `String` | The generated source code |

By default, `on_method_generated` is a no-op. Override it in your class:

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
```

## When It Fires

The hook fires **once per method** after successful validation and installation. If `_()` generates multiple methods in a single call, the hook fires for each one:

```ruby
calc = PersistentCalculator.new

calc._("an instance method named 'increment' that returns n + 1")
# [hook] Generated :increment (scope: instance)

calc._(
  "two methods: 'min_of(a, b)' returns the smaller, " \
  "'max_of(a, b)' returns the larger"
)
# [hook] Generated :min_of (scope: instance)
# [hook] Generated :max_of (scope: instance)
```

## Common Patterns

### Save to Files

```ruby
def on_method_generated(method_name, scope, code)
  filepath = "generated/#{method_name}_#{scope}.rb"
  File.write(filepath, code)
end
```

### Log to a Database

```ruby
def on_method_generated(method_name, scope, code)
  GeneratedMethod.create!(
    name: method_name.to_s,
    scope: scope.to_s,
    source: code,
    class_name: self.class.name
  )
end
```

### Collect for Later Inspection

```ruby
def on_method_generated(method_name, scope, code)
  @generation_log << { method_name: method_name, scope: scope, code: code }
end
```

This pattern is used in the [collaborative robots](../examples/collaborative-robots.md) and [autonomous robots](../examples/autonomous-robots.md) examples.
