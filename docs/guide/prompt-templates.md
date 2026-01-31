# Prompt Templates

SelfAgency uses [ruby_llm-template](https://github.com/danielfriis/ruby_llm-template) for prompt management. The two-stage pipeline (shape and generate) each use a pair of ERB templates.

## Default Template Layout

```
lib/self_agency/prompts/
  shape/
    system.txt.erb    # System prompt for the shape stage
    user.txt.erb      # User prompt for the shape stage
  generate/
    system.txt.erb    # System prompt for the generate stage
    user.txt.erb      # User prompt for the generate stage
```

## Shape Stage Templates

The **shape** stage rewrites a casual English description into a precise Ruby method specification.

**`shape/system.txt.erb`** -- Instructs the LLM to act as a prompt engineer, with rules for rewriting descriptions:

- State the exact method name (snake_case)
- State the method signature with parameter names, types, defaults
- State the return type and value
- Describe the algorithm step by step
- Translate vague terms into concrete Ruby operations
- Output only plain English, no code

**`shape/user.txt.erb`** -- Provides class context and the user's request:

```erb
Rewrite the following casual request into a precise Ruby method specification.

Class context:
- Class name: <%= class_name %>
- Instance variables: <%= ivars %>
- Public methods: <%= methods %>
- Scope: <%= scope_instruction %>

User request:
<%= raw_prompt %>
```

### Available Variables (Shape)

| Variable | Description |
|----------|-------------|
| `class_name` | Name of the including class |
| `ivars` | Comma-separated list of instance variables |
| `methods` | Comma-separated list of public instance methods |
| `scope_instruction` | Human-readable scope description |
| `raw_prompt` | The user's original description |

## Generate Stage Templates

The **generate** stage produces Ruby code from the shaped specification.

**`generate/system.txt.erb`** -- Instructs the LLM to act as a Ruby code generator:

- Return exactly one `def method_name ... end` block
- Do not use dangerous methods (`system`, `exec`, `File`, `IO`, `eval`, etc.)
- Do not wrap code in markdown fences
- The method must be self-contained

**`generate/user.txt.erb`** -- Passes the shaped specification:

```erb
<%= shaped_spec %>
```

### Available Variables (Generate)

| Variable | Description |
|----------|-------------|
| `class_name` | Name of the including class |
| `ivars` | Comma-separated list of instance variables |
| `methods` | Comma-separated list of public instance methods |
| `shaped_spec` | Output from the shape stage |

## Custom Templates

Override `template_directory` to use your own templates:

```ruby
SelfAgency.configure do |config|
  config.template_directory = "/path/to/my/prompts"
  # ...
end
```

Your custom directory must follow the same layout:

```
my_prompts/
  shape/
    system.txt.erb
    user.txt.erb
  generate/
    system.txt.erb
    user.txt.erb
```

All ERB variables listed above are available in your custom templates. This lets you customize the LLM's behavior -- for example, adding domain-specific instructions or constraining the generated code style.
