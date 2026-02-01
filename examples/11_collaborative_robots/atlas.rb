# frozen_string_literal: true

require_relative "robot"

class Atlas < Robot
  # Method named 'generate_weather_data' that takes no parameters. It must return an Array of 24 Hashes (one per hour, index 0..23). Each Hash has these keys (all Symbols): :hour => the integer hour (0..23), :temperature => a Float computed as 20.0 + 8.0 * Math.sin((hour - 6) * Math::PI / 12.0), :humidity => a Float computed as 60.0 + 20.0 * Math.cos((hour - 14) * Math::PI / 12.0), :wind_speed => a Float computed as 10.0 + 5.0 * Math.sin((hour * 7) * Math::PI / 24.0). Do NOT use random numbers. Use only the deterministic formulas above.
  def generate_weather_data
    weather_data = []
    (0..23).each do |hour|
      temperature = 20.0 + 8.0 * Math.sin(((hour - 6) * Math::PI) / 12.0)
      humidity = 60.0 + 20.0 * Math.cos(((hour - 14) * Math::PI) / 12.0)
      wind_speed = 10.0 + 5.0 * Math.sin(((hour * 7) * Math::PI) / 24.0)
      weather_data << {
        hour: hour,
        temperature: temperature,
        humidity: humidity,
        wind_speed: wind_speed
      }
    end
    weather_data
  end

  # Method named 'summarize_raw_data' that takes one parameter (data), an Array of Hashes as described above. It returns a Hash with: :readings_count => data.size, :raw_data => data, :source => "Atlas"
  def summarize_raw_data(data)
    {
      readings_count: data.size,
      raw_data: data,
      source: "Atlas"
    }
  end
end
