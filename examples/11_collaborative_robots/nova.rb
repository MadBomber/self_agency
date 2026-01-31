# frozen_string_literal: true

require_relative "robot"

class Nova < Robot
  # Computes basic statistics from raw weather data. Takes a Hash parameter 'data' containing :raw_data (Array of Hashes with :temperature, :humidity, :wind_speed Floats). Returns a Hash with :avg_temp, :min_temp, :max_temp, :avg_humidity, :avg_wind (all rounded to 1 decimal), :readings (count of readings), and :source. Uses .round(1) for all Float results.
  def compute_weather_statistics(data)
    raw_data = data[:raw_data]
    
    temperatures = []
    humidities = []
    wind_speeds = []
    
    raw_data.each do |reading|
      temperatures << reading[:temperature]
      humidities << reading[:humidity]
      wind_speeds << reading[:wind_speed]
    end
    
    avg_temp = (temperatures.sum / temperatures.length.to_f).round(1)
    min_temp = temperatures.min.round(1)
    max_temp = temperatures.max.round(1)
    avg_humidity = (humidities.sum / humidities.length.to_f).round(1)
    avg_wind = (wind_speeds.sum / wind_speeds.length.to_f).round(1)
    readings = raw_data.length
    source = data[:source] || "unknown"
    
    {
      avg_temp: avg_temp,
      min_temp: min_temp,
      max_temp: max_temp,
      avg_humidity: avg_humidity,
      avg_wind: avg_wind,
      readings: readings,
      source: source
    }
  end

  # Classifies weather conditions based on average temperature, humidity, and wind speed. Takes a Hash parameter 'stats' with :avg_temp, :avg_humidity, :avg_wind (all Floats). Returns a new Hash with the original stats merged with three new classification keys: :temperature_class ("cold", "mild", or "hot"), :humidity_class ("dry", "comfortable", or "humid"), and :wind_class ("calm", "breezy", or "windy"). Preserves all original keys in the input hash.
  def classify_weather(stats)
    result = stats.dup
    temp = stats[:avg_temp]
    humidity = stats[:avg_humidity]
    wind = stats[:avg_wind]
    
    if temp <= 10.0
      result[:temperature_class] = "cold"
    elsif temp <= 25.0
      result[:temperature_class] = "mild"
    else
      result[:temperature_class] = "hot"
    end
    
    if humidity <= 30.0
      result[:humidity_class] = "dry"
    elsif humidity <= 60.0
      result[:humidity_class] = "comfortable"
    else
      result[:humidity_class] = "humid"
    end
    
    if wind <= 5.0
      result[:wind_class] = "calm"
    elsif wind <= 15.0
      result[:wind_class] = "breezy"
    else
      result[:wind_class] = "windy"
    end
    
    result
  end
end
