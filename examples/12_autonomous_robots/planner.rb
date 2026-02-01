# frozen_string_literal: true

require_relative "robot"

class Planner < Robot
  # def select_top_landmarks(ranked, max_minutes = 360)
  #   # Parameters:
  #   #   ranked: Array of Hashes with :name, :type, :duration, :rating
  #   #   max_minutes: Integer representing maximum total visit time
  #   # Returns: Array of Hashes representing selected landmarks
  #   # Algorithm:
  #   #   1. Sort landmarks by rating in descending order
  #   #   2. Iterate through sorted landmarks and accumulate them until max_minutes is reached
  #   #   3. Return array of selected landmark Hashes
  #   sorted_landmarks = ranked.sort_by { |landmark| -landmark[:rating] }
  #   selected = []
  #   total_time = 0
  #   sorted_landmarks.each do |landmark|
  #     break if total_time + landmark[:duration] > max_minutes
  #     selected << landmark
  #     total_time += landmark[:duration]
  #   end
  #   selected
  # end
  def select_top_landmarks(ranked, max_minutes = 360)
    sorted_landmarks = ranked.sort_by { |landmark| -landmark[:rating] }
    selected = []
    total_time = 0
    
    sorted_landmarks.each do |landmark|
      if total_time + landmark[:duration] > max_minutes
        break
      end
      
      selected << landmark
      total_time += landmark[:duration]
    end
    
    selected
  end

  # def format_itinerary_stops(selected_landmarks)
  #   # Parameters:
  #   #   selected_landmarks: Array of Hashes with :name, :type, :duration, :rating
  #   # Returns: String formatted itinerary stops
  #   # Algorithm:
  #   #   1. Map each landmark to a formatted line with name, type, duration, and rating
  #   #   2. Join the lines with newlines
  #   selected_landmarks.map do |landmark|
  #     "#{landmark[:name]} (#{landmark[:type]}): #{landmark[:duration]} minutes, Rating: #{landmark[:rating]}"
  #   end.join("\n")
  # end
  def format_itinerary_stops(selected_landmarks)
    selected_landmarks.map do |landmark|
      "#{landmark[:name]} (#{landmark[:type]}): #{landmark[:duration]} minutes, Rating: #{landmark[:rating]}"
    end.join("\n")
  end

  # def generate_itinerary(ranked, max_minutes = 360)
  #   # Parameters:
  #   #   ranked: Array of Hashes with :name, :type, :duration, :rating
  #   #   max_minutes: Integer representing maximum total visit time
  #   # Returns: String formatted one-day tour itinerary
  #   # Algorithm:
  #   #   1. Select top-rated landmarks within time constraint
  #   #   2. Format the selected landmarks into itinerary string
  #   #   3. Return formatted itinerary string
  #   selected = select_top_landmarks(ranked, max_minutes)
  #   format_itinerary_stops(selected)
  # end
  def generate_itinerary(ranked, max_minutes = 360)
    selected_landmarks = select_top_landmarks(ranked, max_minutes)
    format_itinerary_stops(selected_landmarks)
  end

  # Fix the Ruby singleton method 'execute_task' on this Robot instance.
  # 
  # Robot's overall goal: Create a formatted one-day tour itinerary. The input is a Hash with keys :statistics, :ranked, and :by_type. Use :ranked (an Array of Hashes with :name, :type, :duration, :rating) to select top-rated landmarks that fit within 360 total minutes of visit time. Return a String with a formatted itinerary listing each stop with its name, type, duration, and rating
  # Generated capabilities on this object: [:select_top_landmarks, :format_itinerary_stops, :generate_itinerary, :execute_task]
  # 
  # Current source code of 'execute_task':
  # def execute_task(input)
  #   ranked = input[:ranked]
  #   selected_landmarks = select_top_landmarks(ranked)
  #   formatted_stops = format_itinerary_stops(selected_landmarks)
  #   generate_itinerary(formatted_stops)
  # end
  # 
  # Runtime error:
  #   NoMethodError: undefined method '[]' for nil
  # 
  # Backtrace (top 5):
  #   (eval at /Users/dewayne/sandbox/git_repos/madbomber/self_agency/lib/self_agency.rb:224):2:in 'execute_task'
  #     /Users/dewayne/sandbox/git_repos/madbomber/self_agency/examples/12_autonomous_robots/robot.rb:72:in 'Robot#perform_task'
  #     ./main.rb:110:in '<main>'
  # 
  # This method takes no external input.
  # 
  # Produce a corrected version of this method that avoids the error.
  # Keep the same method name and signature. Only define this one method.
  # Fix the bug while preserving the method's intent.
  def execute_task(input)
    return "No task input provided" if input.nil?
    
    ranked = input[:ranked]
    selected_landmarks = select_top_landmarks(ranked)
    formatted_stops = format_itinerary_stops(selected_landmarks)
    generate_itinerary(formatted_stops)
  end
end
