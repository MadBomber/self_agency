# frozen_string_literal: true

require_relative "robot"

class Echo < Robot
  # Method named 'format_weather_report' that takes one parameter (data), a Hash with these keys: :avg_temp, :min_temp, :max_temp (Floats) :avg_humidity, :avg_wind (Floats) :temperature_class, :humidity_class, :wind_class (Strings) :readings (Integer), :source (String) Return a formatted multi-line String report like: "=== Weather Report ===\n" + "Source: #{data[:source]} | Readings: #{data[:readings]}\n" + "Temperature: #{data[:avg_temp]}°  (min: #{data[:min_temp]}°, max: #{data[:max_temp]}°) [#{data[:temperature_class]}]\n" + "Humidity:    #{data[:avg_humidity]}% [#{data[:humidity_class]}]\n" + "Wind:        #{data[:avg_wind]} km/h [#{data[:wind_class]}]\n" + "======================" Use string interpolation. Return the String, do not print it.
  def format_weather_report(data)
    "=== Weather Report ===\n" \
    "Source: #{data[:source]} | Readings: #{data[:readings]}\n" \
    "Temperature: #{data[:avg_temp]}°  (min: #{data[:min_temp]}°, max: #{data[:max_temp]}°) [#{data[:temperature_class]}]\n" \
    "Humidity:    #{data[:avg_humidity]}% [#{data[:humidity_class]}]\n" \
    "Wind:        #{data[:avg_wind]} km/h [#{data[:wind_class]}]\n" \
    "======================"
  end
end
