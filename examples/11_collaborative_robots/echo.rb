# frozen_string_literal: true

require_relative "robot"

class Echo < Robot
  # Formats a weather report from a hash of weather data. Takes a parameter 'data' which is a Hash containing :avg_temp, :min_temp, :max_temp (Floats), :avg_humidity, :avg_wind (Floats), :temperature_class, :humidity_class, :wind_class (Strings), :readings (Integer), and :source (String). Returns a formatted multi-line String report with temperature, humidity, and wind information including classifications.
  def format_weather_report(data)
    required_keys = [:avg_temp, :min_temp, :max_temp, :avg_humidity, :avg_wind, :temperature_class, :humidity_class, :wind_class, :readings, :source]
    
    required_keys.each do |key|
      raise ArgumentError, "Missing required key: #{key}" unless data.key?(key)
    end
    
    avg_temp = data[:avg_temp]
    min_temp = data[:min_temp]
    max_temp = data[:max_temp]
    avg_humidity = data[:avg_humidity]
    avg_wind = data[:avg_wind]
    temperature_class = data[:temperature_class]
    humidity_class = data[:humidity_class]
    wind_class = data[:wind_class]
    readings = data[:readings]
    source = data[:source]
    
    report = "Weather Report from #{source}\n"
    report += "Readings: #{readings} observations\n"
    report += "Temperature: #{avg_temp}°C (min: #{min_temp}°C, max: #{max_temp}°C) [#{temperature_class}]\n"
    report += "Humidity: #{avg_humidity}% [#{humidity_class}]\n"
    report += "Wind: #{avg_wind} m/s [#{wind_class}]"
    
    report
  end
end
