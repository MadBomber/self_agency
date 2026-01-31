#!/usr/bin/env ruby
# frozen_string_literal: true

# 11_collaborative_robots/main.rb — Collaborative Robots Demo
#
# Demonstrates:
#   - Two-layer LLM approach: analyze task -> generate methods via _()
#   - Three robots collaborating through a shared message bus
#   - Pipeline execution: data generation -> analysis -> reporting
#
# Requires a running Ollama instance with the configured model.

require_relative "robot"

# ---------------------------------------------------------------------------
# Create message bus and robots
# ---------------------------------------------------------------------------

puts "=== Collaborative Robots — Weather Data Pipeline ==="
puts ""

bus = MessageBus.new

atlas = Robot.new(
  name: "Atlas",
  task: <<~TASK,
    You are a data generator robot. Create exactly two instance methods:

    1. Method named 'generate_weather_data' that takes no parameters.
       It must return an Array of 24 Hashes (one per hour, index 0..23).
       Each Hash has these keys (all Symbols):
         :hour        => the integer hour (0..23)
         :temperature => a Float computed as 20.0 + 8.0 * Math.sin((hour - 6) * Math::PI / 12.0)
         :humidity    => a Float computed as 60.0 + 20.0 * Math.cos((hour - 14) * Math::PI / 12.0)
         :wind_speed  => a Float computed as 10.0 + 5.0 * Math.sin((hour * 7) * Math::PI / 24.0)
       Do NOT use random numbers. Use only the deterministic formulas above.

    2. Method named 'summarize_raw_data' that takes one parameter (data),
       an Array of Hashes as described above. It returns a Hash with:
         :readings_count => data.size
         :raw_data       => data
         :source         => "Atlas"
  TASK
  bus: bus
)

puts ""

nova = Robot.new(
  name: "Nova",
  task: <<~TASK,
    You are an analyzer robot. Create exactly two instance methods:

    1. Method named 'compute_basic_statistics' that takes one parameter (data),
       a Hash with key :raw_data containing an Array of Hashes. Each inner Hash
       has keys :temperature, :humidity, :wind_speed (all Floats).
       Compute and return a Hash with:
         :avg_temp      => average of all :temperature values, rounded to 1 decimal
         :min_temp      => minimum :temperature value, rounded to 1 decimal
         :max_temp      => maximum :temperature value, rounded to 1 decimal
         :avg_humidity  => average of all :humidity values, rounded to 1 decimal
         :avg_wind      => average of all :wind_speed values, rounded to 1 decimal
         :readings      => data[:readings_count]
         :source        => data[:source]
       Use .round(1) for all Float results.

    2. Method named 'classify_conditions' that takes one parameter (stats),
       a Hash with keys :avg_temp, :avg_humidity, :avg_wind (all Floats).
       Determine classifications:
         - temperature_class: "cold" if avg_temp < 15, "mild" if < 25, else "hot"
         - humidity_class: "dry" if avg_humidity < 40, "comfortable" if < 70, else "humid"
         - wind_class: "calm" if avg_wind < 8, "breezy" if < 15, else "windy"
       Return stats.merge with the three new keys (:temperature_class, :humidity_class,
       :wind_class) added, preserving all existing keys.
  TASK
  bus: bus
)

puts ""

echo = Robot.new(
  name: "Echo",
  task: <<~TASK,
    You are a reporter robot. Create exactly one instance method:

    1. Method named 'format_weather_report' that takes one parameter (data),
       a Hash with these keys:
         :avg_temp, :min_temp, :max_temp (Floats)
         :avg_humidity, :avg_wind (Floats)
         :temperature_class, :humidity_class, :wind_class (Strings)
         :readings (Integer), :source (String)
       Return a formatted multi-line String report like:

       "=== Weather Report ===\\n" +
       "Source: \#{data[:source]} | Readings: \#{data[:readings]}\\n" +
       "Temperature: \#{data[:avg_temp]}°  (min: \#{data[:min_temp]}°, max: \#{data[:max_temp]}°) [\#{data[:temperature_class]}]\\n" +
       "Humidity:    \#{data[:avg_humidity]}% [\#{data[:humidity_class]}]\\n" +
       "Wind:        \#{data[:avg_wind]} km/h [\#{data[:wind_class]}]\\n" +
       "======================"

       Use string interpolation. Return the String, do not print it.
  TASK
  bus: bus
)

# ---------------------------------------------------------------------------
# Display capabilities summary
# ---------------------------------------------------------------------------

puts ""
puts "=== Capabilities Summary ==="
[atlas, nova, echo].each do |robot|
  puts "#{robot.name}: #{robot.capabilities.inspect}"
end

puts ""
puts "=== Generated Source Code ==="
[atlas, nova, echo].each do |robot|
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

# Step 1: Atlas generates and summarizes weather data
puts "Step 1: Atlas generates weather data..."
atlas_result = atlas.execute
atlas.send_message(to: "Nova", content: atlas_result)
puts "Atlas produced #{atlas_result[:raw_data]&.size || 0} readings"
puts ""

# Step 2: Nova analyzes the data
puts "Step 2: Nova analyzes the data..."
nova_input = nova.inbox.last&.dig(:content)
nova_result = nova.execute(nova_input)
nova.send_message(to: "Echo", content: nova_result)
puts "Nova computed statistics and classifications"
puts ""

# Step 3: Echo formats the report
puts "Step 3: Echo formats the final report..."
echo_input = echo.inbox.last&.dig(:content)
final_report = echo.execute(echo_input)
puts ""

# ---------------------------------------------------------------------------
# Display results
# ---------------------------------------------------------------------------

puts "=== Final Weather Report ==="
puts final_report.to_s
puts ""

bus.print_log
puts ""

# ---------------------------------------------------------------------------
# Generation statistics
# ---------------------------------------------------------------------------

puts "=== Generation Statistics ==="
total_methods = 0
total_lines   = 0
[atlas, nova, echo].each do |robot|
  methods = robot.generation_log.size
  lines   = robot.generation_log.sum { |e| e[:code].lines.size }
  total_methods += methods
  total_lines   += lines
  puts "#{robot.name}: #{methods} method(s), #{lines} lines of generated code"
end
puts "Total: #{total_methods} methods, #{total_lines} lines of generated code"

# ---------------------------------------------------------------------------
# Save generated robots as subclasses
# ---------------------------------------------------------------------------

puts ""
puts "=== Saving Generated Robots ==="
[atlas, nova, echo].each do |robot|
  path = robot._save!(as: robot.name)
  puts "#{robot.name}: saved to #{path}"
end
