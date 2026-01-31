# frozen_string_literal: true

require_relative "robot"

class Analyst < Robot
  # def calculate_statistics(landmarks)
  #   # Calculate statistics from landmarks array
  #   # Parameters: landmarks - Array of Hashes with :name, :type, :duration, :rating
  #   # Returns: Hash with :avg_rating, :avg_duration, :total_duration, :count
  #   
  #   return { avg_rating: 0.0, avg_duration: 0, total_duration: 0, count: 0 } if landmarks.empty?
  #   
  #   total_rating = landmarks.sum { |landmark| landmark[:rating] }
  #   total_duration = landmarks.sum { |landmark| landmark[:duration] }
  #   count = landmarks.length
  #   
  #   {
  #     avg_rating: total_rating.to_f / count,
  #     avg_duration: total_duration.to_f / count,
  #     total_duration: total_duration,
  #     count: count
  #   }
  # end
  def calculate_statistics(landmarks)
    return { avg_rating: 0.0, avg_duration: 0.0, total_duration: 0, count: 0 } if landmarks.empty?
    
    total_rating = landmarks.sum { |landmark| landmark[:rating] }
    total_duration = landmarks.sum { |landmark| landmark[:duration] }
    count = landmarks.length
    
    {
      avg_rating: total_rating.to_f / count,
      avg_duration: total_duration.to_f / count,
      total_duration: total_duration,
      count: count
    }
  end

  # def rank_landmarks(landmarks)
  #   # Sort landmarks by rating in descending order
  #   # Parameters: landmarks - Array of Hashes with :name, :type, :duration, :rating
  #   # Returns: Array of Hashes sorted by :rating descending
  #   
  #   landmarks.sort_by { |landmark| -landmark[:rating] }
  # end
  def rank_landmarks(landmarks)
    landmarks.sort_by { |landmark| -landmark[:rating] }
  end

  # def group_landmarks_by_type(landmarks)
  #   # Group landmarks by their type
  #   # Parameters: landmarks - Array of Hashes with :name, :type, :duration, :rating
  #   # Returns: Hash with type names as keys and Arrays of landmarks as values
  #   
  #   grouped = {}
  #   landmarks.each do |landmark|
  #     type = landmark[:type]
  #     grouped[type] ||= []
  #     grouped[type] << landmark
  #   end
  #   grouped
  # end
  def group_landmarks_by_type(landmarks)
    grouped = {}
    landmarks.each do |landmark|
      type = landmark[:type]
      grouped[type] ||= []
      grouped[type] << landmark
    end
    grouped
  end

  # An instance method named 'execute_task' that orchestrates the following
  # goal: Analyze landmark data. The input is an Array of Hashes, each with keys :name (String), :type (String), :duration (Integer), :rating (Float). Return a Hash with three keys: :statistics (a Hash with :avg_rating, :avg_duration, :total_duration, :count), :ranked (the landmarks Array sorted by :rating descending), :by_type (a Hash grouping landmarks by :type)
  # 
  # It takes one parameter (input) which is the data passed in from a previous stage.
  # 
  # Available helper methods on this object: calculate_statistics, rank_landmarks, group_landmarks_by_type
  # 
  # Call the helper methods in whatever order makes sense to accomplish the goal.
  # Return the final result. Do NOT define the helper methods — they already exist.
  # Only define the execute_task method itself.
  def execute_task(input)
    statistics = calculate_statistics(input)
    ranked = rank_landmarks(input)
    by_type = group_landmarks_by_type(input)
    
    {
      statistics: statistics,
      ranked: ranked,
      by_type: by_type
    }
  end
end
