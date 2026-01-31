# Development Setup

## Prerequisites

- Ruby >= 3.2.0
- Bundler

## Getting Started

Clone the repository and install dependencies:

```bash
git clone https://github.com/madbomber/self_agency.git
cd self_agency
bin/setup
```

`bin/setup` installs gem dependencies via Bundler.

## Dependencies

### Runtime

| Gem | Purpose |
|-----|---------|
| `ruby_llm` | LLM provider communication |
| `ruby_llm-template` | ERB prompt template management |
| `method_source` | Source code retrieval for file-defined methods |

### Development

| Gem | Purpose |
|-----|---------|
| `minitest` | Test framework |
| `rake` | Task runner |
| `simplecov` | Code coverage |
| `debug_me` | Debugging output |
| `irb` | Interactive console |

## Console

Start an interactive console with the gem preloaded:

```bash
bin/console
```

## Project Structure

```
self_agency/
  lib/
    self_agency.rb              # Main module
    self_agency/
      version.rb                # VERSION constant
      errors.rb                 # Error hierarchy
      configuration.rb          # Configuration + singleton methods
      sandbox.rb                # Runtime sandbox
      validator.rb              # Static analysis + validation
      generator.rb              # LLM communication
      saver.rb                  # _save! helpers
      prompts/                  # ERB templates
        shape/
          system.txt.erb
          user.txt.erb
        generate/
          system.txt.erb
          user.txt.erb
  test/
    test_helper.rb              # Test setup
    test_configuration.rb       # Configuration tests
    test_generator.rb           # Generator tests
    test_pipeline.rb            # Pipeline tests
    test_sandbox.rb             # Sandbox tests
    test_save.rb                # _save! tests
    test_source_for.rb          # Source inspection tests
    test_templates.rb           # Template tests
    test_validator.rb           # Validator tests
  examples/                     # 12 example scripts
  docs/                         # This documentation
```
