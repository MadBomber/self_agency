# frozen_string_literal: true

require_relative "robot"

class Atlas < Robot
  # Generates weather data for 24 hours with deterministic calculations. Returns an Array of 24 Hashes, each containing :hour (Integer), :temperature (Float), :humidity (Float), and :wind_speed (Float) keys. The temperature is calculated as 20.0 + 8.0 * Math.sin((hour - 6) * Math::PI / 12.0), humidity as 60.0 + 20.0 * Math.cos((hour - 14) * Math::PI / 12.0), and wind_speed as 10.0 + 5.0 * Math.sin((hour * 7) * Math::PI / 24.0).
  def generate_weather_data
    weather_data = []
    (0..23).each do |hour|
      temperature = 20.0 + 8.0 * Math.sin((hour - 6) * Math::PI / 12.0)
      humidity = 60.0 + 20.0 * Math.cos((hour - 14) * Math::PI / 12.0)
      wind_speed = 10.0 + 5.0 * Math.sin((hour * 7) * Math::PI / 24.0)
      weather_data << { hour: hour, temperature: temperature, humidity: humidity, wind_speed: wind_speed }
    end
    weather_data
  end

  # Creates a summary hash from raw weather data. Takes one parameter 'data' which is an Array of Hashes with :hour, :temperature, :humidity, and :wind_speed keys. Returns a Hash with :readings_count (Integer), :raw_data (Array of Hashes), and :source (String) set to 'Atlas'.
  def weather_summary(data)
    readings_count = data.length
    {
      :readings_count => readings_count,
      :raw_data => data.dup,
      :source => 'Atlas'
    }
  end
end
