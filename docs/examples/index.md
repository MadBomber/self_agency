# Examples

SelfAgency ships with 12 examples that progressively demonstrate its features. All examples live in the `examples/` directory.

## Running Examples

Most examples require a running LLM. The default configuration targets Ollama:

```bash
# Start Ollama
ollama serve

# Run an example
bundle exec ruby examples/01_basic_usage.rb
```

Examples 06 and 07 run offline (no LLM required) as they only exercise configuration and error handling.

## Example Index

| # | Name | Features | LLM Required |
|---|------|----------|:---:|
| 01 | [Basic Usage](basic-examples.md#01-basic-usage) | `_()`, single method generation | Yes |
| 02 | [Multiple Methods](basic-examples.md#02-multiple-methods) | Multiple methods from one call | Yes |
| 03 | [Scopes](basic-examples.md#03-scopes) | Instance, singleton, class scopes | Yes |
| 04 | [Source Inspection](basic-examples.md#04-source-inspection) | `_source_for`, file fallback | Yes |
| 05 | [Lifecycle Hook](basic-examples.md#05-lifecycle-hook) | `on_method_generated` | Yes |
| 06 | [Configuration](basic-examples.md#06-configuration) | All config options, `reset!`, `ensure_configured!` | No |
| 07 | [Error Handling](basic-examples.md#07-error-handling) | Error hierarchy, rescue patterns | No |
| 08 | [Class Context](basic-examples.md#08-class-context) | Instance variables, method awareness | Yes |
| 09 | [Method Override](basic-examples.md#09-method-override) | Replacing existing methods | Yes |
| 10 | [Full Workflow](full-workflow.md) | Complete real-world workflow | Yes |
| 11 | [Collaborative Robots](collaborative-robots.md) | Multi-robot pipeline, message bus | Yes |
| 12 | [Autonomous Robots](autonomous-robots.md) | Three-layer LLM, self-repair | Yes |

Examples 01--09 are covered in [Basic Examples](basic-examples.md). Examples 10--12 each have their own deep-dive page.
