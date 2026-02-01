# SelfAgency Module

The main mixin module. Include it in any class to enable LLM-powered method generation.

```ruby
class MyClass
  include SelfAgency
end
```

Including `SelfAgency` adds instance methods to the class and extends it with `SelfAgency::ClassMethods`.

---

## Instance Methods

### `_(description, scope: :instance)`

Generate and install one or more methods from a natural language description.

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `description` | `String` | *(required)* | Natural language description of the method(s) |
| `scope` | `Symbol` | `:instance` | One of `:instance`, `:singleton`, `:class` |

**Returns:** `Array<Symbol>` -- names of the newly defined methods.

**Raises:**

| Exception | Condition |
|-----------|-----------|
| `SelfAgency::Error` | `SelfAgency.configure` has not been called |
| `SelfAgency::GenerationError` | LLM returned `nil` at shape or generate stage |
| `SelfAgency::ValidationError` | Generated code is empty, malformed, or has syntax errors |
| `SelfAgency::SecurityError` | Generated code contains a dangerous pattern |

**Example:**

```ruby
names = obj._("an instance method to add two integers")
#=> [:add]

names = obj._("a class method named 'self.ping' that returns 'pong'", scope: :class)
#=> [:ping]
```

---

### `self_agency_generate(description, scope: :instance)`

Alias for `_()`. Provides a named alternative when `_` conflicts with other conventions (e.g., i18n):

```ruby
names = obj.self_agency_generate("a method to add two integers")
#=> [:add]
```

---

### `_source_for(method_name)`

Return the source code for a method, or `nil` if unavailable.

For LLM-generated methods, returns the code with the original description as a comment header. For file-defined methods, falls back to the `method_source` gem.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `method_name` | `Symbol` or `String` | The method to look up |

**Returns:** `String` or `nil`.

**Example:**

```ruby
puts obj._source_for(:add)
# >> # an instance method to add two integers
# >> def add(a, b)
# >>   a + b
# >> end
```

---

### `_save!(as:, path: nil)`

Save the object's generated methods as a subclass in a Ruby source file.

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `as` | `String` or `Symbol` | *(required)* | Subclass name (snake_case converted to CamelCase) |
| `path` | `String` or `nil` | `nil` | Output file path (defaults to snake_cased name + `.rb`) |

**Returns:** `String` -- the file path written to.

**Raises:**

| Exception | Condition |
|-----------|-----------|
| `ArgumentError` | `as:` is not a String or Symbol |
| `SelfAgency::Error` | No generated methods to save |
| `SelfAgency::Error` | Parent class is anonymous |

**Example:**

```ruby
path = obj._save!(as: :calculator)
#=> "calculator.rb"

path = obj._save!(as: :calculator, path: "lib/calculator.rb")
#=> "lib/calculator.rb"
```

---

### `on_method_generated(method_name, scope, code)`

Lifecycle hook called once per generated method. Override in your class to persist or log generated methods.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `method_name` | `Symbol` | Name of the generated method |
| `scope` | `Symbol` | `:instance`, `:singleton`, or `:class` |
| `code` | `String` | The generated source code |

**Default behavior:** No-op.

**Example:**

```ruby
def on_method_generated(method_name, scope, code)
  File.write("generated/#{method_name}.rb", code)
end
```

---

## Class Methods (via ClassMethods)

### `_source_for(method_name)`

Class-level version of `_source_for`. Works identically to the instance method but is called on the class.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `method_name` | `Symbol` or `String` | The method to look up |

**Returns:** `String` or `nil`.

**Example:**

```ruby
puts MyClass._source_for(:add)
```

---

### `_source_versions_for(method_name)`

Return the version history for a generated method. Each entry records the code, description, generating instance, and timestamp.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `method_name` | `Symbol` or `String` | The method to look up |

**Returns:** `Array<Hash>` -- each Hash contains:

| Key | Type | Description |
|-----|------|-------------|
| `:code` | `String` | The generated source code |
| `:description` | `String` | The description passed to `_()` |
| `:instance_id` | `Integer` | `object_id` of the instance that generated it |
| `:at` | `Time` | When the method was generated |

Returns an empty array if no versions exist.

**Example:**

```ruby
obj._("add two integers")
obj._("add two integers, raise ArgumentError if either is negative")

versions = MyClass._source_versions_for(:add)
versions.size  #=> 2
versions.last[:at]          #=> 2025-01-31 12:34:56 -0500
versions.last[:description] #=> "add two integers, raise ArgumentError if either is negative"
```
