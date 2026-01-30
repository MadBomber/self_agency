#!/usr/bin/env ruby
# frozen_string_literal: true

# 12_autonomous_robots/main.rb — Autonomous Robots Demo
#
# Demonstrates:
#   - Three-layer LLM approach: decompose goal -> generate helpers -> generate orchestrator
#   - Robots receive "what" not "how" — LLM decides method names, algorithms, data structures
#   - Pipeline execution: collect landmarks -> analyze data -> plan itinerary
#
# Contrast with Demo 11:
#   Demo 11 dictates method names and algorithms in the task description.
#   Demo 12 gives only a high-level goal and lets the LLM decide everything.
#
# Requires a running Ollama instance with the configured model.

require_relative "robot"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

SelfAgency.configure do |config|
  config.provider        = :ollama
  config.model           = "qwen3-coder:30b"
  config.api_base        = "http://localhost:11434/v1"
  config.request_timeout = 120
end

# ---------------------------------------------------------------------------
# Create message bus and autonomous robots
# ---------------------------------------------------------------------------

puts "=== Autonomous Robots — City Landmarks Tour Pipeline ==="
puts ""

bus = MessageBus.new

collector = Robot.new(
  name: "Collector",
  goal: "Build a catalog of 8 fictional city landmarks including names, types, " \
        "estimated visit durations in minutes, and visitor ratings on a 1-to-5 scale",
  bus: bus
)

puts ""

analyst = Robot.new(
  name: "Analyst",
  goal: "Analyze a collection of landmark data to compute visit statistics, " \
        "rank landmarks by rating, and group them by type",
  bus: bus,
  receives_input: true
)

puts ""

planner = Robot.new(
  name: "Planner",
  goal: "Create a formatted one-day tour itinerary from analyzed landmark data, " \
        "selecting the top-rated attractions that fit within 6 hours of total visit time",
  bus: bus,
  receives_input: true
)

# ---------------------------------------------------------------------------
# Display capabilities and generated source
# ---------------------------------------------------------------------------

puts ""
puts "=== Capabilities Summary ==="
[collector, analyst, planner].each do |robot|
  puts "#{robot.name}: #{robot.capabilities.inspect}"
end

puts ""
puts "=== Generated Source Code ==="
[collector, analyst, planner].each do |robot|
  robot.generation_log.each do |entry|
    puts "--- #{robot.name}##{entry[:method_name]} ---"
    puts entry[:code]
    puts ""
  end
end

# ---------------------------------------------------------------------------
# Execute the pipeline
# ---------------------------------------------------------------------------

puts "=== Executing Pipeline ==="
puts ""

# Step 1: Collector builds a landmark catalog (no input)
puts "Step 1: Collector builds landmark catalog..."
collector_result = collector.perform_task
collector.send_message(to: "Analyst", content: collector_result)
puts "Collector produced: #{collector_result.class}"
puts ""

# Step 2: Analyst processes the catalog
puts "Step 2: Analyst analyzes landmark data..."
analyst_input = analyst.inbox.last&.dig(:content)
analyst_result = analyst.perform_task(analyst_input)
analyst.send_message(to: "Planner", content: analyst_result)
puts "Analyst produced: #{analyst_result.class}"
puts ""

# Step 3: Planner creates the itinerary
puts "Step 3: Planner creates tour itinerary..."
planner_input = planner.inbox.last&.dig(:content)
final_itinerary = planner.perform_task(planner_input)
puts ""

# ---------------------------------------------------------------------------
# Display results
# ---------------------------------------------------------------------------

puts "=== Final Tour Itinerary ==="
puts final_itinerary.to_s
puts ""

bus.print_log
puts ""

# ---------------------------------------------------------------------------
# Generation statistics
# ---------------------------------------------------------------------------

puts "=== Generation Statistics ==="
total_methods = 0
total_lines   = 0
[collector, analyst, planner].each do |robot|
  methods = robot.generation_log.size
  lines   = robot.generation_log.sum { |e| e[:code].lines.size }
  total_methods += methods
  total_lines   += lines
  puts "#{robot.name}: #{methods} method(s), #{lines} lines of generated code"
end
puts "Total: #{total_methods} methods, #{total_lines} lines of generated code"

# ---------------------------------------------------------------------------
# Repair statistics (if any)
# ---------------------------------------------------------------------------

all_repairs = [collector, analyst, planner].flat_map(&:repair_log)
unless all_repairs.empty?
  puts ""
  puts "=== Repair Statistics ==="
  all_repairs.each do |entry|
    status = entry[:success] ? "SUCCESS" : "FAILED"
    puts "  [#{status}] #{entry[:method_name]} — #{entry[:error]}"
  end
  puts "Total repair attempts: #{all_repairs.size}, " \
       "successful: #{all_repairs.count { |e| e[:success] }}, " \
       "failed: #{all_repairs.count { |e| !e[:success] }}"
end
