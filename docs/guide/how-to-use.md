# How to Use SelfAgency

## Two Schools of Software Design

Software architects have long worked with two complementary approaches to building systems. The names change over the decades — structured vs. exploratory, waterfall vs. iterative, specification-first vs. prototype-first — but the underlying concepts remain the same: **Top-Down** and **Bottom-Up**.

### Top-Down Design

Top-Down design begins at the highest level of abstraction. You define the overall system architecture, decompose it into subsystems, decompose those into modules, and continue refining until you arrive at the concrete methods and functions that do the actual work.

```
System
  └── Subsystem A
  │     └── Module A1
  │     │     └── method_x
  │     │     └── method_y
  │     └── Module A2
  │           └── method_z
  └── Subsystem B
        └── ...
```

This approach excels at maintaining coherence across large systems. You know the shape of the whole before you write a line of implementation code.

### Bottom-Up Design

Bottom-Up design starts at the opposite end. You write the lowest-level functions first — the critical algorithms, the core transformations, the essential business logic — and then compose those pieces into higher-level abstractions.

```
method_x + method_y  →  Module A1
Module A1 + Module A2  →  Subsystem A
Subsystem A + Subsystem B  →  System
```

This approach excels at producing battle-tested components. Each building block is proven through direct experimentation before it is wired into a larger structure.

### The Pragmatic Architect

A skilled architect does not choose one approach exclusively. The most effective strategy combines both:

- **Top-Down** to establish the overall architecture, define interfaces, and ensure the system hangs together coherently.
- **Bottom-Up** to experiment with the critical pieces, validate assumptions, and build confidence that the low-level logic actually works.

The two approaches meet in the middle. Top-Down gives you the map. Bottom-Up gives you proven ground truth.

## Where SelfAgency Fits

SelfAgency is a Bottom-Up experimentation tool. It lives in the space where you are exploring an idea, testing a hypothesis, or prototyping a piece of business logic — before you commit to a full architectural design.

The typical workflow looks like this:

### 1. Start an IRB Session

```bash
bin/console
# or
bundle exec irb -r self_agency
```

### 2. Configure Your LLM

```ruby
SelfAgency.configure do |config|
  config.provider = :ollama
  config.model    = "qwen3-coder:30b"
  config.api_base = "http://localhost:11434/v1"
end
```

### 3. Sketch a Class Around Your Domain

You do not need a complete design. Start with the concept:

```ruby
class PricingEngine
  include SelfAgency

  def initialize(base_rate:, discount_tiers:)
    @base_rate = base_rate
    @discount_tiers = discount_tiers
  end
end

engine = PricingEngine.new(
  base_rate: 100.0,
  discount_tiers: { silver: 0.05, gold: 0.10, platinum: 0.15 }
)
```

### 4. Generate and Experiment

Describe the behavior you need in plain language. Try it. Refine the description. Try again.

```ruby
engine._("calculate the discounted price for a given tier and quantity")
engine.calculate_discounted_price(:gold, 5)
#=> 450.0

# Not quite what you wanted? Inspect the source:
puts engine._source_for(:calculate_discounted_price)

# Refine and regenerate:
engine._(
  "calculate the discounted price: multiply base_rate by quantity, " \
  "then subtract the tier's discount percentage from discount_tiers. " \
  "Raise ArgumentError if the tier is not recognized."
)
```

Each iteration gives you a working method you can call immediately. You see the generated source, test it with real inputs, and adjust your description until the logic is right.

### 5. Save What Works

Once a method behaves correctly, persist it:

```ruby
engine._save!(:calculate_discounted_price)
# Writes the method source to a file you can incorporate into your codebase
```

### 6. Build Up

With proven components in hand, you can now make informed architectural decisions. You know what the critical methods look like, what their interfaces are, and how they behave. Wire them into your Top-Down design with confidence.

## The Experimentation Loop

The core value of SelfAgency is shortening the feedback loop during Bottom-Up exploration:

```
Describe  →  Generate  →  Test  →  Inspect  →  Refine
    ↑                                              │
    └──────────────────────────────────────────────┘
```

You stay in IRB the entire time. No file switching, no boilerplate, no deploy cycle. Just describe what you need, see if it works, and iterate until it does.

This makes SelfAgency particularly useful for:

- **Prototyping business rules** — "calculate the late fee given these conditions"
- **Exploring algorithms** — "sort these records by weighted score using these criteria"
- **Validating data transformations** — "parse this CSV row into a normalized hash"
- **Building up a utility class** — generate methods one at a time, test each, save the keepers

When you are done experimenting, you have real, tested Ruby methods — not pseudocode or diagrams. Those methods become the foundation your architecture is built on.
