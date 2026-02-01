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

The **shape** stage rewrites a casual language description into a precise Ruby method specification.

**`shape/system.txt.erb`** -- Instructs the LLM to act as a prompt engineer, with rules for rewriting descriptions:

- State the exact method name (snake_case)
- State the method signature with parameter names, types, defaults
- State the return type and value
- Describe the algorithm step by step
- Translate vague terms into concrete Ruby operations
- Output only plain language, no code

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

!!! note
    The template instructs the LLM to return "exactly one" method definition. However, when describing multiple methods in a single `_()` call, some LLMs return multiple `def...end` blocks despite this instruction. SelfAgency handles this gracefully -- it splits the output into individual method blocks and installs each one separately.

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

### Why Customize?

The default prompts are tuned for general-purpose code generation, but different providers and models respond best to different prompt styles. You may want to customize templates when:

- **Switching providers or models** -- A prompt that works well with Ollama's Qwen may produce poor results with OpenAI's GPT-4o or Anthropic's Claude. Some models need more explicit instructions; others perform better with fewer constraints. Smaller models may need step-by-step algorithmic guidance that a larger model would find redundant.
- **Domain-specific generation** -- If your class operates in a specific domain (financial calculations, data science, text processing), you can add domain rules and conventions directly into the system prompt so every generated method follows them.
- **Code style enforcement** -- You may want generated methods to follow your project's conventions: frozen string literals, specific naming patterns, guard clauses, or particular error handling styles.
- **Controlling output format** -- Some models wrap output in markdown fences or include chain-of-thought reasoning despite instructions not to. Tailoring the prompt to your model's quirks reduces the sanitization needed.

### Setup

Start by copying the default prompts into your project:

```bash
cp -r $(bundle show self_agency)/lib/self_agency/prompts my_prompts
```

Then point SelfAgency at your copy:

```ruby
SelfAgency.configure do |config|
  config.template_directory = File.expand_path("my_prompts", __dir__)
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

All ERB variables listed above are available in your custom templates.

### Example: Adapting the Generate Prompt for a Different Model

The default `generate/system.txt.erb` is concise:

```erb
You are a Ruby code generator. You MUST respond with ONLY a Ruby method
definition — nothing else. No explanation, no markdown fences, no comments
outside the method, no extra text.

Context for the class you are writing a method for:
- Class name: <%= class_name %>
- Instance variables: <%= ivars %>
- Public methods: <%= methods %>

Rules:
- Return exactly one `def method_name ... end` block.
- Do NOT use system, exec, backticks, File, IO, Kernel, require, load, eval, or send.
- Do NOT wrap the code in markdown fences.
- The method must be self-contained.
```

A smaller or less instruction-following model might ignore the "no markdown fences" rule, or include conversational preamble before the code. You could adapt it with stronger guardrails:

```erb
TASK: Generate a Ruby method definition.

CRITICAL FORMAT RULES:
1. Your ENTIRE response must be a single `def ... end` block.
2. Do NOT output any text before `def` or after `end`.
3. Do NOT use ``` fences. Do NOT use <think> tags.
4. Do NOT include comments, explanations, or notes.

If you output anything other than a method definition, the parse will fail.

Class: <%= class_name %>
Instance variables: <%= ivars %>
Existing methods: <%= methods %>

FORBIDDEN constructs (will be rejected):
system, exec, spawn, fork, backticks, File, IO, Kernel, Open3,
Process, require, load, eval, send, __send__, remove_method, undef_method

Write ONLY the def ... end block now.
```

This version uses imperative language, repeats the format constraint, and explicitly warns about parse failure -- techniques that help smaller models stay on track.
