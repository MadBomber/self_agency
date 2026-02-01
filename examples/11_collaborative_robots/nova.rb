# frozen_string_literal: true

require_relative "robot"

class Nova < Robot
  # Compute basic statistics from raw data. Takes one parameter (data), a Hash with key :raw_data containing an Array of Hashes. Each inner Hash has keys :temperature, :humidity, :wind_speed (all Floats). Compute and return a Hash with: :avg_temp => average of all :temperature values, rounded to 1 decimal, :min_temp => minimum :temperature value, rounded to 1 decimal, :max_temp => maximum :temperature value, rounded to 1 decimal, :avg_humidity => average of all :humidity values, rounded to 1 decimal, :avg_wind => average of all :wind_speed values, rounded to 1 decimal, :readings => data[:readings_count], :source => data[:source]. Use .round(1) for all Float results.
  def compute_statistics(data)
    raw_data = data[:raw_data]
    readings_count = data[:readings_count]
    source = data[:source]
    
    temps = raw_data.map { |reading| reading[:temperature] }
    humidities = raw_data.map { |reading| reading[:humidity] }
    wind_speeds = raw_data.map { |reading| reading[:wind_speed] }
    
    avg_temp = (temps.sum / temps.length.to_f).round(1)
    min_temp = temps.min.round(1)
    max_temp = temps.max.round(1)
    avg_humidity = (humidities.sum / humidities.length.to_f).round(1)
    avg_wind = (wind_speeds.sum / wind_speeds.length.to_f).round(1)
    
    {
      :avg_temp => avg_temp,
      :min_temp => min_temp,
      :max_temp => max_temp,
      :avg_humidity => avg_humidity,
      :avg_wind => avg_wind,
      :readings => readings_count,
      :source => source
    }
  end

  # Classify weather conditions based on statistics. Takes one parameter (stats), a Hash with keys :avg_temp, :avg_humidity, :avg_wind (all Floats). Determine classifications: - temperature_class: "cold" if avg_temp < 15, "mild" if < 25, else "hot" - humidity_class: "dry" if avg_humidity < 40, "comfortable" if < 70, else "humid" - wind_class: "calm" if avg_wind < 8, "breezy" if < 15, else "windy" Return stats.merge with the three new keys (:temperature_class, :humidity_class, :wind_class) added, preserving all existing keys.
  def classify_weather_conditions(stats)
    temperature_class = if stats[:avg_temp] < 15.0
                          "cold"
                        elsif stats[:avg_temp] < 25.0
                          "mild"
                        else
                          "hot"
                        end

    humidity_class = if stats[:avg_humidity] < 40.0
                       "dry"
                     elsif stats[:avg_humidity] < 70.0
                       "comfortable"
                     else
                       "humid"
                     end

    wind_class = if stats[:avg_wind] < 8.0
                   "calm"
                 elsif stats[:avg_wind] < 15.0
                   "breezy"
                 else
                   "windy"
                 end

    stats.merge(:temperature_class => temperature_class, :humidity_class => humidity_class, :wind_class => wind_class)
  end
end
