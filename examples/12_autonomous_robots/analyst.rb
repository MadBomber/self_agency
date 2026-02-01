# frozen_string_literal: true

require_relative "robot"

class Analyst < Robot
  # Fix the Ruby singleton method 'calculate_statistics' on this Robot instance.
  # 
  # Robot's overall goal: Analyze landmark data. The input is an Array of Hashes, each with keys :name (String), :type (String), :duration (Integer), :rating (Float). Return a Hash with three keys: :statistics (a Hash with :avg_rating, :avg_duration, :total_duration, :count), :ranked (the landmarks Array sorted by :rating descending), :by_type (a Hash grouping landmarks by :type)
  # Generated capabilities on this object: [:calculate_statistics, :sort_by_rating, :group_by_type, :analyze_landmarks, :execute_task]
  # 
  # Current source code of 'calculate_statistics':
  # def calculate_statistics(landmarks)
  #   total_duration = 0
  #   total_rating = 0.0
  #   count = landmarks.length
  #   
  #   landmarks.each do |landmark|
  #     total_duration += landmark[:duration]
  #     total_rating += landmark[:rating]
  #   end
  #   
  #   avg_rating = count.zero? ? 0.0 : total_rating / count
  #   avg_duration = count.zero? ? 0.0 : total_duration.to_f / count
  #   
  #   statistics = {
  #     :avg_rating => avg_rating,
  #     :avg_duration => avg_duration,
  #     :total_duration => total_duration,
  #     :count => count
  #   }
  #   
  #   ranked = landmarks.sort_by { |landmark| -landmark[:rating] }
  #   
  #   by_type = {}
  #   landmarks.each do |landmark|
  #     type = landmark[:type]
  #     by_type[type] ||= []
  #     by_type[type] << landmark
  #   end
  #   
  #   {
  #     :statistics => statistics,
  #     :ranked => ranked,
  #     :by_type => by_type
  #   }
  # end
  # 
  # Runtime error:
  #   TypeError: no implicit conversion of Symbol into Integer
  # 
  # Backtrace (top 5):
  #   (eval at /Users/dewayne/sandbox/git_repos/madbomber/self_agency/lib/self_agency.rb:224):7:in 'block in calculate_statistics'
  #     (eval at /Users/dewayne/sandbox/git_repos/madbomber/self_agency/lib/self_agency.rb:224):6:in 'Hash#each'
  #     (eval at /Users/dewayne/sandbox/git_repos/madbomber/self_agency/lib/self_agency.rb:224):6:in 'calculate_statistics'
  #     (eval at /Users/dewayne/sandbox/git_repos/madbomber/self_agency/lib/self_agency.rb:224):3:in 'execute_task'
  #     /Users/dewayne/sandbox/git_repos/madbomber/self_agency/examples/12_autonomous_robots/robot.rb:72:in 'Robot#perform_task'
  # 
  # The execute_task method received input of type Array.
  # Array with 8 element(s).
  # Sample element keys: [:name, :type, :duration, :rating]
  # Sample element: {name: "Pool Recreational", type: "Educational", duration: 115, rating: 3.9}
  # 
  # Produce a corrected version of this method that avoids the error.
  # Keep the same method name and signature. Only define this one method.
  # Fix the bug while preserving the method's intent.
  def calculate_statistics(landmarks)
    total_duration = 0
    total_rating = 0.0
    count = landmarks.length

    landmarks.each do |landmark|
      total_duration += landmark[:duration]
      total_rating += landmark[:rating]
    end

    avg_rating = count.zero? ? 0.0 : total_rating / count
    avg_duration = count.zero? ? 0 : total_duration.to_f / count

    statistics = {
      :statistics => {
        :avg_rating => avg_rating,
        :avg_duration => avg_duration,
        :total_duration => total_duration,
        :count => count
      },
      :ranked => landmarks.sort_by { |landmark| -landmark[:rating] },
      :by_type => landmarks.group_by { |landmark| landmark[:type] }
    }

    statistics
  end

  # def sort_by_rating(landmarks)
  #   # Parameters: landmarks - Array of Hashes with keys :name, :type, :duration, :rating
  #   # Return: Array of Hashes sorted by :rating in descending order
  #   # Algorithm: Use sort_by with descending rating comparison
  #   landmarks.sort_by { |landmark| -landmark[:rating] }
  # end
  def sort_by_rating(landmarks)
    landmarks.sort_by { |landmark| -landmark[:rating] }
  end

  # def group_by_type(landmarks)
  #   # Parameters: landmarks - Array of Hashes with keys :name, :type, :duration, :rating
  #   # Return: Hash with type names as keys and Arrays of landmark Hashes as values
  #   # Algorithm: Use group_by to create type-based grouping
  #   landmarks.group_by { |landmark| landmark[:type] }
  # end
  def group_by_type(landmarks)
    landmarks.group_by { |landmark| landmark[:type] }
  end

  # def analyze_landmarks(landmarks)
  #   # Parameters: landmarks - Array of Hashes with keys :name, :type, :duration, :rating
  #   # Return: Hash with keys :statistics, :ranked, :by_type
  #   # Algorithm: Combine statistics, sorting, and grouping operations
  #   {
  #     statistics: calculate_statistics(landmarks),
  #     ranked: sort_by_rating(landmarks),
  #     by_type: group_by_type(landmarks)
  #   }
  # end
  def analyze_landmarks(landmarks)
    {
      statistics: calculate_statistics(landmarks),
      ranked: sort_by_rating(landmarks),
      by_type: group_by_type(landmarks)
    }
  end

  # An instance method named 'execute_task' that orchestrates the following
  # goal: Analyze landmark data. The input is an Array of Hashes, each with keys :name (String), :type (String), :duration (Integer), :rating (Float). Return a Hash with three keys: :statistics (a Hash with :avg_rating, :avg_duration, :total_duration, :count), :ranked (the landmarks Array sorted by :rating descending), :by_type (a Hash grouping landmarks by :type)
  # 
  # It takes one parameter (input) which is the data passed in from a previous stage.
  # 
  # Available helper methods on this object: calculate_statistics, sort_by_rating, group_by_type, analyze_landmarks
  # 
  # Call the helper methods in whatever order makes sense to accomplish the goal.
  # Return the final result. Do NOT define the helper methods — they already exist.
  # Only define the execute_task method itself.
  def execute_task(input)
    processed_data = analyze_landmarks(input)
    statistics = calculate_statistics(processed_data)
    ranked = sort_by_rating(processed_data)
    by_type = group_by_type(processed_data)
    {
      :statistics => statistics,
      :ranked => ranked,
      :by_type => by_type
    }
  end
end
