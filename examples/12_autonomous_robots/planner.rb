# frozen_string_literal: true

require_relative "robot"

class Planner < Robot
  # def select_top_landmarks(ranked, max_minutes = 360)
  #   # Selects top-rated landmarks that fit within the maximum time limit
  #   # Parameters:
  #   #   ranked: Array of Hashes with keys :name, :type, :duration, :rating
  #   #   max_minutes: Integer representing maximum time in minutes
  #   # Returns: Array of Hashes representing selected landmarks
  #   
  #   selected = []
  #   total_time = 0
  #   
  #   ranked.each do |landmark|
  #     if total_time + landmark[:duration] <= max_minutes
  #       selected << landmark
  #       total_time += landmark[:duration]
  #     else
  #       break
  #     end
  #   end
  #   
  #   selected
  # end
  def select_top_landmarks(ranked, max_minutes = 360)
    selected = []
    total_time = 0
    
    ranked.each do |landmark|
      if total_time + landmark[:duration] <= max_minutes
        selected << landmark
        total_time += landmark[:duration]
      else
        break
      end
    end
    
    selected
  end

  # def format_landmark_entry(landmark)
  #   # Formats a single landmark entry for the itinerary
  #   # Parameters:
  #   #   landmark: Hash with keys :name, :type, :duration, :rating
  #   # Returns: String formatted landmark entry
  #   
  #   "#{landmark[:name]} (#{landmark[:type]}) - #{landmark[:duration]} min - Rating: #{landmark[:rating]}"
  # end
  def format_landmark_entry(landmark)
    "#{landmark[:name]} (#{landmark[:type]}) - #{landmark[:duration]} min - Rating: #{landmark[:rating]}"
  end

  # def build_itinerary_string(selected_landmarks)
  #   # Builds the complete formatted itinerary string from selected landmarks
  #   # Parameters:
  #   #   selected_landmarks: Array of Hashes representing selected landmarks
  #   # Returns: String with formatted itinerary
  #   
  #   return "No landmarks selected" if selected_landmarks.empty?
  #   
  #   lines = ["Today's Tour Itinerary:"]
  #   lines.concat(selected_landmarks.map { |landmark| format_landmark_entry(landmark) })
  #   
  #   lines.join("\n")
  # end
  def build_itinerary_string(selected_landmarks)
    return "No landmarks selected" if selected_landmarks.empty?
    
    lines = ["Today's Tour Itinerary:"]
    lines.concat(selected_landmarks.map { |landmark| format_landmark_entry(landmark) })
    lines.join("\n")
  end

  # An instance method named 'execute_task' that orchestrates the following
  # goal: Create a formatted one-day tour itinerary. The input is a Hash with keys :statistics, :ranked, and :by_type. Use :ranked (an Array of Hashes with :name, :type, :duration, :rating) to select top-rated landmarks that fit within 360 total minutes of visit time. Return a String with a formatted itinerary listing each stop with its name, type, duration, and rating
  # 
  # It takes one parameter (input) which is the data passed in from a previous stage.
  # 
  # Available helper methods on this object: select_top_landmarks, format_landmark_entry, build_itinerary_string
  # 
  # Call the helper methods in whatever order makes sense to accomplish the goal.
  # Return the final result. Do NOT define the helper methods — they already exist.
  # Only define the execute_task method itself.
  def execute_task(input)
    selected_landmarks = select_top_landmarks(input[:ranked])
    build_itinerary_string(selected_landmarks)
  end
end
