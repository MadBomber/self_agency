# frozen_string_literal: true

# robot.rb — Autonomous Robot with three-layer LLM self-generation
#
# Layer 1 (Decompose): Direct RubyLLM.chat().ask() breaks a high-level goal
#   into a JSON array of helper method specs. The LLM decides method names,
#   parameter signatures, and algorithms — the user only states "what", not "how".
# Layer 2 (Generate Helpers): Loops through specs, calls _() for each.
#   SelfAgency handles shape -> generate -> validate -> sandbox eval.
# Layer 3 (Generate Orchestrator): A final _() call generates an execute_task
#   method that calls the helpers in whatever order the LLM decides.

require "json"
require_relative "../lib/message_bus"
require_relative "../lib/setup"

class Robot
  include SelfAgency

  MAX_REPAIR_ATTEMPTS = 3

  attr_reader :name, :goal, :bus, :inbox, :capabilities, :generation_log, :repair_log

  def initialize(name:, goal:, bus:, receives_input: false)
    @name           = name
    @goal           = goal
    @bus            = bus
    @receives_input = receives_input
    @inbox          = []
    @capabilities   = []
    @generation_log = []
    @repair_log     = []

    bus.register(self)

    # Layer 1 — Decompose goal into helper method specs
    puts "#{@name}: Decomposing goal..."
    specs = decompose_task(goal)
    puts "#{@name}: LLM decomposed goal into #{specs.size} helper(s)"

    # Layer 2 — Generate each helper method via _()
    specs.each do |spec|
      description = spec["description"]
      puts "#{@name}: Generating helper — #{description[0, 80]}..."

      begin
        defined_methods = _(description, scope: :singleton)
        @capabilities.concat(defined_methods)
        puts "#{@name}: Generated #{defined_methods.inspect}"
      rescue SelfAgency::Error => e
        puts "#{@name}: Failed to generate helper: #{e.message}"
      end
    end

    # Layer 3 — Generate orchestrator that calls the helpers
    puts "#{@name}: Generating orchestrator for #{@capabilities.size} helper(s)..."
    generate_orchestrator

    puts "#{@name}: Ready with capabilities: #{@capabilities.inspect}"
  end

  def perform_task(input = nil)
    attempts = 0

    begin
      arity = method(:execute_task).arity
      puts "#{@name}: Running execute_task (input: #{input.class})"

      if arity == 0
        execute_task
      else
        execute_task(input)
      end
    rescue => error
      attempts += 1
      puts "#{@name}: Error (attempt #{attempts}/#{MAX_REPAIR_ATTEMPTS}): #{error.class}: #{error.message}"

      if attempts < MAX_REPAIR_ATTEMPTS
        repair_method(error, input)
        retry
      else
        puts "#{@name}: MALFUNCTION — failed after #{MAX_REPAIR_ATTEMPTS} repair attempts: #{error.message}"
        nil
      end
    end
  end

  def receive_message(from:, content:)
    @inbox << { from: from, content: content }
    puts "#{@name}: Received message from #{from}"
  end

  def send_message(to:, content:)
    @bus.deliver(from: @name, to: to, content: content)
  end

  def broadcast(content:)
    @bus.broadcast(from: @name, content: content)
  end

  def on_method_generated(method_name, scope, code)
    @generation_log << { method_name: method_name, scope: scope, code: code }
  end

  private

  # Self-repair: identify the failing method from the backtrace, regenerate it via LLM.
  # Includes goal, capabilities, input shape, and sibling source for full context.
  def repair_method(error, input = nil)
    failing_method = identify_failing_method(error)
    current_source = find_generated_source(failing_method)
    puts "#{@name}: Repairing #{failing_method.inspect}"

    # Build a snapshot of all generated method sources for context
    sibling_sources = @generation_log
      .select { |e| e[:method_name] != failing_method }
      .map { |e| "  def #{e[:method_name]}(...) — see generation log" }
      .join("\n")

    # Describe the input data shape so the LLM understands what it's working with
    input_shape = describe_data_shape(input)

    description = <<~DESC
      Fix the Ruby singleton method '#{failing_method}' on this Robot instance.

      Robot's overall goal: #{@goal}
      Generated capabilities on this object: #{@capabilities.inspect}

      Current source code of '#{failing_method}':
      #{current_source}

      Runtime error:
        #{error.class}: #{error.message}

      Backtrace (top 5):
        #{error.backtrace&.first(5)&.join("\n    ")}

      #{input_shape}

      Produce a corrected version of this method that avoids the error.
      Keep the same method name and signature. Only define this one method.
      Fix the bug while preserving the method's intent.
    DESC

    defined_methods = _(description, scope: :singleton)
    @repair_log << { method_name: failing_method, error: "#{error.class}: #{error.message}", success: true }
    puts "#{@name}: Repaired #{failing_method} -> #{defined_methods.inspect}"
  rescue SelfAgency::Error => e
    @repair_log << { method_name: failing_method, error: "#{error.class}: #{error.message}", success: false }
    puts "#{@name}: Repair generation failed: #{e.message}"
  end

  # Scan the backtrace for a method name that matches one of our generated capabilities.
  # Handles both Ruby <3.4 (`method') and Ruby >=3.4 ('Class#method') backtrace formats.
  def identify_failing_method(error)
    return :execute_task unless error.backtrace

    error.backtrace.each do |line|
      match = line.match(/in ['`](?:\w+#)?(\w+)'/)
      next unless match

      method_name = match[1].to_sym
      return method_name if @capabilities.include?(method_name) && method_name != :execute_task
    end

    :execute_task
  end

  # Look up the most recent generated source for a method from the generation log.
  def find_generated_source(method_name)
    entry = @generation_log.reverse.find { |e| e[:method_name] == method_name }
    entry ? entry[:code] : "(source not found)"
  end

  # Build a human-readable description of the input data shape for the repair prompt.
  # Shows class, keys, and a sample element so the LLM understands the actual structure.
  def describe_data_shape(input)
    return "This method takes no external input." if input.nil?

    lines = ["The execute_task method received input of type #{input.class}."]

    case input
    when Hash
      lines << "Top-level keys: #{input.keys.inspect}"
      input.each do |key, value|
        case value
        when Array
          lines << "  input[#{key.inspect}] is an Array with #{value.size} element(s)."
          if value.first.is_a?(Hash)
            lines << "  Sample element keys: #{value.first.keys.inspect}"
            lines << "  Sample element: #{value.first.inspect[0, 200]}"
          end
        else
          lines << "  input[#{key.inspect}] is a #{value.class}: #{value.inspect[0, 100]}"
        end
      end
    when Array
      lines << "Array with #{input.size} element(s)."
      if input.first.is_a?(Hash)
        lines << "Sample element keys: #{input.first.keys.inspect}"
        lines << "Sample element: #{input.first.inspect[0, 200]}"
      end
    else
      lines << "Value preview: #{input.inspect[0, 200]}"
    end

    lines.join("\n")
  end

  # Layer 1 — Ask the LLM to decompose a high-level goal into helper method specs.
  # Returns an Array of Hashes with "description" keys.
  def decompose_task(goal)
    cfg  = SelfAgency.configuration
    chat = RubyLLM.chat(model: cfg.model, provider: cfg.provider)

    prompt = <<~PROMPT
      You are an autonomous task decomposition engine. Given a high-level goal,
      decide what Ruby helper methods are needed to accomplish it. YOU choose
      the method names, parameters, algorithms, and data structures.

      Return a JSON array of method specifications. Each element must have:
        - "description": a precise Ruby method specification including the method
          name you chose (snake_case), parameter names and types, return type,
          and a detailed algorithm. This description will be given to a Ruby code
          generator, so be precise and complete.

      Rules:
        - Choose clear, descriptive method names
        - Design clean data structures (prefer Hashes with Symbol keys and Arrays)
        - Each method should do one thing well
        - Methods should be composable — later methods can use output of earlier ones
        - Do NOT include an orchestrator method — only helper methods
        - Keep to 2-4 helper methods maximum

      Respond with ONLY the JSON array. No markdown fences, no explanation.

      Goal: #{goal}
    PROMPT

    response = chat.ask(prompt)
    raw      = response.content.to_s.strip

    raw = raw.gsub(/<think>.*?<\/think>/m, "")
    raw = raw.sub(/\A```\w*\n?/, "").sub(/\n?```\s*\z/, "")
    raw.strip!

    JSON.parse(raw)
  rescue JSON::ParserError => e
    puts "#{@name}: Failed to parse decomposition: #{e.message}"
    []
  end

  # Layer 3 — Generate an orchestrator method that calls the helpers.
  # The LLM decides how to wire the helpers together to achieve the goal.
  def generate_orchestrator
    helper_list = @capabilities.map(&:to_s).join(", ")
    input_clause = if @receives_input
                     "It takes one parameter (input) which is the data passed in from a previous stage."
                   else
                     "It takes no parameters."
                   end

    description = <<~DESC
      An instance method named 'execute_task' that orchestrates the following
      goal: #{@goal}

      #{input_clause}

      Available helper methods on this object: #{helper_list}

      Call the helper methods in whatever order makes sense to accomplish the goal.
      Return the final result. Do NOT define the helper methods — they already exist.
      Only define the execute_task method itself.
    DESC

    begin
      defined_methods = _(description, scope: :singleton)
      @capabilities.concat(defined_methods)
      puts "#{@name}: Generated orchestrator #{defined_methods.inspect}"
    rescue SelfAgency::Error => e
      puts "#{@name}: Failed to generate orchestrator: #{e.message}"
    end
  end
end
