<div align="center">
  <h1>SelfAgency</h1>
  Describe what you want in plain language, get working methods back.<br/>
  SelfAgency is a mixin module that gives any Ruby class the ability to<br/>
  generate and install methods at runtime via an LLM.<br/>
  <br/>
  <img src="assets/images/self_agency.gif" alt="SelfAgency Demo" width="100%">
  <h2>Key Features</h2>
</div>

<table>
  <tr>
    <td width="50%" valign="top">
      <ul>
        <li><strong>Natural language to Ruby methods</strong> — describe what you want, get working code</li>
        <li><strong>Multiple methods at once</strong> — generate related methods in a single call</li>
        <li><strong>Three scopes</strong> — instance, singleton, and class methods</li>
        <li><strong>Two-stage LLM pipeline</strong> — shape the prompt, then generate code</li>
      </ul>
    </td>
    <td width="50%" valign="top">
      <ul>
        <li><strong>Security by default</strong> — 26 static patterns + runtime sandbox</li>
        <li><strong>Automatic retries</strong> — self-corrects on validation failure</li>
        <li><strong>Source inspection &amp; versioning</strong> — view code and track history</li>
        <li><strong>Provider agnostic</strong> — any LLM via <a href="https://github.com/crmne/ruby_llm">ruby_llm</a></li>
      </ul>
    </td>
  </tr>
</table>

> [!CAUTION]
> This is an experiment. It may not be fit for any specific purpose.  Its micro-prompting.  Instead of asking Claude Code, CodeX or Gemini to create an entire application, you can use SelfAgency to generate individual methods.  So far the experiments are showing good success with methods that perform math stuff on its input.


## Quick Example

```ruby
require "self_agency"

SelfAgency.configure do |config|
  config.provider = :ollama
  config.model    = "qwen3-coder:30b"
  config.api_base = "http://localhost:11434/v1"
end

class Calculator
  include SelfAgency
end

calc = Calculator.new
calc._("an instance method to add two integers, return the result")
#=> [:add]

calc.add(3, 7)
#=> 10
```

## How It Works

Your casual description is first "shaped" into a precise Ruby method specification, then passed through a multi-stage pipeline:

1. **Shape** -- Rewrites your casual description into a precise Ruby method specification
2. **Generate** -- Produces `def...end` block(s) from the shaped spec
3. **Sanitize** -- Strips markdown fences and `<think>` blocks
4. **Validate** -- Checks for empty code, missing `def...end`, syntax errors, and dangerous patterns
5. **Retry** -- On validation/security failure, feeds the error back to the LLM for self-correction (up to `generation_retries` attempts)
6. **Sandbox Eval** -- Evaluates code inside a cached sandbox module that shadows dangerous Kernel methods

## Requirements

- Ruby >= 3.2.0
- An LLM provider (Ollama by default, or any provider supported by ruby_llm)

## Getting Started

Head to the [Installation](getting-started/installation.md) guide to add SelfAgency to your project, then follow the [Quick Start](getting-started/quick-start.md) for a complete walkthrough. For a broader perspective on where SelfAgency fits in your development process, see [How to Use SelfAgency](guide/how-to-use.md).
