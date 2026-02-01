# frozen_string_literal: true

require_relative "robot"

class Planner < Robot
  # def select_top_landmarks(ranked_landmarks, max_minutes=360)
  #   # Select landmarks that fit within the maximum time limit
  #   # Input: ranked_landmarks - Array of Hashes with :name, :type, :duration, :rating
  #   #        max_minutes - Integer representing maximum time in minutes
  #   # Output: Array of Hashes representing selected landmarks
  #   
  #   selected = []
  #   total_time = 0
  #   
  #   ranked_landmarks.each do |landmark|
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
  def select_top_landmarks(ranked_landmarks, max_minutes=360)
    selected = []
    total_time = 0
    
    ranked_landmarks.each do |landmark|
      if total_time + landmark[:duration] <= max_minutes
        selected << landmark
        total_time += landmark[:duration]
      else
        break
      end
    end
    
    selected
  end

  # def format_itinerary_section(landmarks)
  #   # Format a section of the itinerary with landmark details
  #   # Input: landmarks - Array of Hashes with :name, :type, :duration, :rating
  #   # Output: String representing formatted itinerary section
  #   
  #   return "No landmarks selected" if landmarks.empty?
  #   
  #   lines = ["Landmarks to Visit:"]
  #   
  #   landmarks.each_with_index do |landmark, index|
  #     lines << "#{index + 1}. #{landmark[:name]} (#{landmark[:type]}) -- #{landmark[:duration]} minutes -- Rating: #{landmark[:rating]}"
  #   end
  #   
  #   lines.join("\n")
  # end
  def format_itinerary_section(landmarks)
    return "No landmarks selected" if landmarks.empty?
    
    lines = ["Landmarks to Visit:"]
    
    landmarks.each_with_index do |landmark, index|
      lines << "#{index + 1}. #{landmark[:name]} (#{landmark[:type]}) -- #{landmark[:duration]} minutes -- Rating: #{landmark[:rating]}"
    end
    
    lines.join("\n")
  end

  # def generate_itinerary_string(statistics, ranked_landmarks, by_type)
  #   # Generate the complete formatted itinerary string
  #   # Input: statistics - Hash with statistical information
  #   #        ranked_landmarks - Array of Hashes with :name, :type, :duration, :rating
  #   #        by_type - Hash grouping landmarks by type
  #   # Output: String representing the complete formatted itinerary
  #   
  #   selected_landmarks = select_top_landmarks(ranked_landmarks)
  #   itinerary_section = format_itinerary_section(selected_landmarks)
  #   
  #   "#{itinerary_section}"
  # end
  def generate_itinerary_string(statistics, ranked_landmarks, by_type)
    selected_landmarks = select_top_landmarks(ranked_landmarks)
    itinerary_section = format_itinerary_section(selected_landmarks)
    itinerary_section
  end

  # Fix the Ruby singleton method 'execute_task' on this Robot instance.
  # 
  # Robot's overall goal: Create a formatted one-day tour itinerary. The input is a Hash with keys :statistics, :ranked, and :by_type. Use :ranked (an Array of Hashes with :name, :type, :duration, :rating) to select top-rated landmarks that fit within 360 total minutes of visit time. Return a String with a formatted itinerary listing each stop with its name, type, duration, and rating
  # Generated capabilities on this object: [:select_top_landmarks, :format_itinerary_section, :generate_itinerary_string, :execute_task]
  # 
  # Current source code of 'execute_task':
  # def execute_task(input)
  #   ranked = input[:ranked]
  #   filtered_landmarks = select_top_landmarks(ranked)
  #   formatted_sections = filtered_landmarks.map { |landmark| format_itinerary_section(landmark) }
  #   generate_itinerary_string(formatted_sections)
  # end
  # 
  # Runtime error:
  #   NoMethodError: undefined method '[]' for nil
  # 
  # Backtrace (top 5):
  #   (eval at /Users/dewayne/sandbox/git_repos/madbomber/self_agency/lib/self_agency.rb:265):2:in 'execute_task'
  #     /Users/dewayne/sandbox/git_repos/madbomber/self_agency/examples/12_autonomous_robots/robot.rb:72:in 'Robot#perform_task'
  #     ./main.rb:110:in '<main>'
  # 
  # This method takes no external input.
  # 
  # Produce a corrected version of this method that avoids the error.
  # Keep the same method name and signature. Only define this one method.
  # Fix the bug while preserving the method's intent.
  def execute_task(input)
    return "" if input.nil?
    
    ranked = input[:ranked]
    return "" if ranked.nil?
    
    filtered_landmarks = select_top_landmarks(ranked)
    return "" if filtered_landmarks.nil? || filtered_landmarks.empty?
    
    formatted_sections = filtered_landmarks.map { |landmark| format_itinerary_section(landmark) }
    generate_itinerary_string(formatted_sections)
  end
end
