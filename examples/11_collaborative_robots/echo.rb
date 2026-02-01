# frozen_string_literal: true

require_relative "robot"

class Echo < Robot
  # Return a formatted multi-line String report like: "=== Weather Report ===\n" + "Source: #{data[:source]} | Readings: #{data[:readings]}\n" + "Temperature: #{data[:avg_temp]}°  (min: #{data[:min_temp]}°, max: #{data[:max_temp]}°) [#{data[:temperature_class]}]\n" + "Humidity:    #{data[:avg_humidity]}% [#{data[:humidity_class]}]\n" + "Wind:        #{data[:avg_wind]} km/h [#{data[:wind_class]}]\n" + "======================". Use string interpolation. Return the String, do not print it.
  def weather_report
    data = {
      source: "Weather Station 42",
      readings: "24 hr",
      avg_temp: 22.5,
      min_temp: 18.2,
      max_temp: 28.7,
      temperature_class: "Mild",
      avg_humidity: 65,
      humidity_class: "Moderate",
      avg_wind: 12.3,
      wind_class: "Light Breeze"
    }

    report = "=== Weather Report ===\n"
    report += "Source: #{data[:source]} | Readings: #{data[:readings]}\n"
    report += "Temperature: #{data[:avg_temp]}°  (min: #{data[:min_temp]}°, max: #{data[:max_temp]}°) [#{data[:temperature_class]}]\n"
    report += "Humidity:    #{data[:avg_humidity]}% [#{data[:humidity_class]}]\n"
    report += "Wind:        #{data[:avg_wind]} km/h [#{data[:wind_class]}]\n"
    report += "======================"

    report
  end
end
