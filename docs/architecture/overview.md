# Architecture Overview

SelfAgency uses a two-stage LLM pipeline with multi-layer security to generate and install methods at runtime.

## Pipeline

```mermaid
flowchart TD
    A["User calls _('description')"] --> B[ensure_configured!]
    B --> C[Shape Stage]
    C --> D{Shaped spec nil?}
    D -->|Yes| E[Raise GenerationError]
    D -->|No| F[Generate Stage]
    F --> G{Raw code nil?}
    G -->|Yes| E
    G -->|No| H[Sanitize]
    H --> I[Validate]
    I --> J{Valid?}
    J -->|No| K[Raise ValidationError or SecurityError]
    J -->|Yes| L[Sandbox Eval]
    L --> M[Split Methods]
    M --> N[Store Source]
    N --> O[Fire on_method_generated Hook]
    O --> P["Return Array<Symbol>"]
```

## Stage 1: Shape

The shape stage rewrites a casual English description into a precise Ruby method specification. It uses ERB templates from the `shape/` directory.

The LLM receives class context:

- **Class name** -- e.g., `Calculator`
- **Instance variables** -- e.g., `@data, @name`
- **Public methods** -- e.g., `add, subtract, mean`
- **Scope instruction** -- e.g., "This will be an instance method available on all instances of the class."

The shape stage does **not** produce code. It produces a refined natural language specification that the generate stage can work with reliably.

## Stage 2: Generate

The generate stage takes the shaped specification and produces a `def...end` block. It uses templates from the `generate/` directory.

The LLM receives the same class context plus the shaped specification from stage 1.

## Post-Processing

After generation, the raw LLM output goes through three steps:

### Sanitize

Strips artifacts from the LLM response:

- Markdown code fences (` ```ruby ... ``` `)
- `<think>` blocks (used by some models for chain-of-thought reasoning)
- Leading/trailing whitespace

### Validate

Four checks run in sequence:

1. **Non-empty** -- Code must not be blank
2. **Structure** -- Must contain at least one `def...end` block
3. **Security** -- Must not match any `DANGEROUS_PATTERNS`
4. **Syntax** -- Must compile via `RubyVM::InstructionSequence.compile`

### Sandbox Eval

The validated code is evaluated inside an anonymous module that includes `SelfAgency::Sandbox`. This module shadows dangerous Kernel methods, placing them ahead of Kernel in Ruby's method resolution order (MRO).

The module is then prepended to the appropriate target:

| Scope | Prepend Target |
|-------|---------------|
| `:instance` | `self.class` |
| `:singleton` | `singleton_class` |
| `:class` | `self.class.singleton_class` |

## Module Structure

```mermaid
classDiagram
    class SelfAgency {
        +_(description, scope) Array~Symbol~
        +_source_for(method_name) String?
        +_save!(as, path) String
        +on_method_generated(name, scope, code)
    }

    class ClassMethods {
        +_source_for(method_name) String?
    }

    class Configuration {
        +provider Symbol
        +model String
        +api_base String
        +request_timeout Integer
        +max_retries Integer
        +retry_interval Float
        +template_directory String
    }

    class Sandbox {
        -system(*) raises SecurityError
        -exec(*) raises SecurityError
        -spawn(*) raises SecurityError
        -fork(*) raises SecurityError
        -open(*) raises SecurityError
    }

    class Validator {
        +DANGEROUS_PATTERNS Regexp
        -self_agency_sanitize(raw) String
        -self_agency_validate!(code)
    }

    class Generator {
        -self_agency_ask_with_template(name, **vars) String?
        -self_agency_shape(prompt, scope) String?
        -self_agency_generation_vars() Hash
    }

    class Saver {
        -self_agency_to_class_name(value) String
        -self_agency_to_snake_case(name) String
        -self_agency_relative_require(output, source) String
        -self_agency_build_subclass_source(...) String
    }

    SelfAgency --> ClassMethods : extends including class
    SelfAgency --> Configuration : uses
    SelfAgency --> Sandbox : includes in eval module
    SelfAgency --> Validator : validates code
    SelfAgency --> Generator : calls LLM
    SelfAgency --> Saver : persists methods
```

## File Layout

```
lib/
  self_agency.rb            # Main module, public API, eval logic
  self_agency/
    version.rb              # VERSION constant
    errors.rb               # Error hierarchy
    configuration.rb        # Configuration class and singleton methods
    sandbox.rb              # Runtime sandbox module
    validator.rb            # DANGEROUS_PATTERNS, sanitize, validate!
    generator.rb            # LLM communication and prompt shaping
    saver.rb                # _save! helpers
    prompts/
      shape/
        system.txt.erb      # Shape stage system prompt
        user.txt.erb        # Shape stage user prompt
      generate/
        system.txt.erb      # Generate stage system prompt
        user.txt.erb        # Generate stage user prompt
```
