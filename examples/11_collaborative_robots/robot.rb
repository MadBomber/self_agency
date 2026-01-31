# frozen_string_literal: true

# robot.rb — Robot class with two-layer LLM self-generation
#
# Layer 1 (Analyze): Direct RubyLLM.chat().ask() decomposes a task into
#   a JSON array of method specifications.
# Layer 2 (Generate): Loops through specs, calls _() for each.
#   SelfAgency handles shape -> generate -> validate -> sandbox eval.

require "json"
require_relative "../lib/message_bus"
require_relative "../lib/setup"

class Robot
  include SelfAgency

  attr_reader :name, :task, :bus, :inbox, :capabilities, :generation_log

  def initialize(name:, task:, bus:)
    @name           = name
    @task           = task
    @bus            = bus
    @inbox          = []
    @capabilities   = []
    @generation_log = []

    bus.register(self)

    puts "#{@name}: Analyzing task..."
    specs = analyze_task(task)
    puts "#{@name}: Found #{specs.size} method(s) to generate"

    specs.each do |spec|
      method_name = spec["name"]
      description = spec["description"]
      puts "#{@name}: Generating '#{method_name}' — #{description}"

      begin
        defined_methods = _(description)
        @capabilities.concat(defined_methods)
        puts "#{@name}: Successfully generated #{defined_methods.inspect}"
      rescue SelfAgency::Error => e
        puts "#{@name}: Failed to generate '#{method_name}': #{e.message}"
      end
    end

    puts "#{@name}: Ready with capabilities: #{@capabilities.inspect}"
  end

  def execute(input = nil)
    result = nil

    @capabilities.each do |cap|
      arity = method(cap).arity

      if arity == 0 && result.nil?
        result = public_send(cap)
      elsif arity != 0 && !result.nil?
        result = public_send(cap, result)
      elsif arity != 0 && result.nil? && !input.nil?
        result = public_send(cap, input)
      end
    end

    result
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

  def analyze_task(description)
    cfg  = SelfAgency.configuration
    chat = RubyLLM.chat(model: cfg.model, provider: cfg.provider)

    prompt = <<~PROMPT
      You are a task decomposition engine. Given a task description, return a JSON
      array of method specifications. Each element must have:
        - "name": the Ruby method name (snake_case)
        - "description": a precise description for a Ruby code generator, including
          the method name, parameter names and types, return type, and algorithm
        - "takes_input": boolean, true if the method accepts a parameter

      Respond with ONLY the JSON array. No markdown fences, no explanation.

      Task: #{description}
    PROMPT

    response = chat.ask(prompt)
    raw      = response.content.to_s.strip

    # Sanitize the same way SelfAgency does — strip <think> blocks and markdown fences
    raw = raw.gsub(/<think>.*?<\/think>/m, "")
    raw = raw.sub(/\A```\w*\n?/, "").sub(/\n?```\s*\z/, "")
    raw.strip!

    JSON.parse(raw)
  rescue JSON::ParserError => e
    puts "#{@name}: Failed to parse task analysis: #{e.message}"
    []
  end
end
