# Testing

SelfAgency uses Minitest. All tests run offline -- they exercise configuration, validation, sanitization, and sandboxing without calling an LLM.

## Running Tests

Run the full test suite:

```bash
rake test
```

This is the default Rake task, so `rake` alone works too:

```bash
rake
```

## Running Individual Tests

Run a specific test file:

```bash
bundle exec ruby -Ilib -Itest test/test_validator.rb
```

Run a single test method:

```bash
bundle exec ruby -Ilib -Itest test/test_validator.rb -n test_method_name
```

## Test Structure

| File | Tests |
|------|-------|
| `test_configuration.rb` | Configuration options, `reset!`, `ensure_configured!` |
| `test_generator.rb` | Generator helper methods |
| `test_pipeline.rb` | End-to-end pipeline logic |
| `test_sandbox.rb` | Runtime sandbox blocks dangerous methods |
| `test_save.rb` | `_save!` file generation |
| `test_source_for.rb` | `_source_for` at instance and class level |
| `test_templates.rb` | Prompt template loading |
| `test_validator.rb` | Sanitization, validation, security patterns |

## Test Design

Tests define a `SampleClass` that includes `SelfAgency` for testing private helpers via `send`. This avoids needing a live LLM connection -- the tests exercise the internal machinery directly:

```ruby
class SampleClass
  include SelfAgency
end

# Test private helpers
obj = SampleClass.new
obj.send(:self_agency_validate!, code)
obj.send(:self_agency_sanitize, raw)
```

## Code Coverage

SimpleCov runs automatically with every test execution. Coverage reports are generated in the `coverage/` directory after each `rake test` run:

```bash
rake test
# Coverage report written to coverage/
```

Open `coverage/index.html` in a browser to view the detailed report.
