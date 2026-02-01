# frozen_string_literal: true

require_relative "robot"

class Analyst < Robot
  # Fix the Ruby singleton method 'calculate_statistics' on this Robot instance.
  # 
  # Robot's overall goal: Analyze landmark data. The input is an Array of Hashes, each with keys :name (String), :type (String), :duration (Integer), :rating (Float). Return a Hash with three keys: :statistics (a Hash with :avg_rating, :avg_duration, :total_duration, :count), :ranked (the landmarks Array sorted by :rating descending), :by_type (a Hash grouping landmarks by :type)
  # Generated capabilities on this object: [:calculate_statistics, :sort_by_rating, :group_by_type, :execute_task]
  # 
  # Current source code of 'calculate_statistics':
  # def calculate_statistics(landmarks)
  #   total_duration = 0
  #   rating_sum = 0.0
  #   
  #   landmarks.each do |landmark|
  #     total_duration += landmark[:duration]
  #     rating_sum += landmark[:rating]
  #   end
  #   
  #   avg_rating = landmarks.length > 0 ? rating_sum / landmarks.length : 0.0
  #   avg_duration = landmarks.length > 0 ? total_duration.to_f / landmarks.length : 0.0
  #   
  #   {
  #     avg_rating: avg_rating,
  #     avg_duration: avg_duration,
  #     total_duration: total_duration,
  #     count: landmarks.length
  #   }
  # end
  # 
  # Runtime error:
  #   NoMethodError: undefined method 'each' for nil
  # 
  # Backtrace (top 5):
  #   (eval at /Users/dewayne/sandbox/git_repos/madbomber/self_agency/lib/self_agency.rb:265):5:in 'calculate_statistics'
  #     (eval at /Users/dewayne/sandbox/git_repos/madbomber/self_agency/lib/self_agency.rb:265):2:in 'execute_task'
  #     /Users/dewayne/sandbox/git_repos/madbomber/self_agency/examples/12_autonomous_robots/robot.rb:72:in 'Robot#perform_task'
  #     ./main.rb:102:in '<main>'
  # 
  # This method takes no external input.
  # 
  # Produce a corrected version of this method that avoids the error.
  # Keep the same method name and signature. Only define this one method.
  # Fix the bug while preserving the method's intent.
  def calculate_statistics(landmarks)
    landmarks = landmarks || []
    
    total_duration = 0
    rating_sum = 0.0
    count = 0
    
    landmarks.each do |landmark|
      next unless landmark.is_a?(Hash)
      next unless landmark[:duration].is_a?(Integer)
      next unless landmark[:rating].is_a?(Float)
      
      total_duration += landmark[:duration]
      rating_sum += landmark[:rating]
      count += 1
    end
    
    avg_rating = count > 0 ? rating_sum / count : 0.0
    avg_duration = count > 0 ? total_duration.to_f / count : 0.0
    
    statistics = {
      :avg_rating => avg_rating,
      :avg_duration => avg_duration,
      :total_duration => total_duration,
      :count => count
    }
    
    ranked = landmarks.sort_by { |landmark| -landmark[:rating] }
    
    by_type = landmarks.group_by { |landmark| landmark[:type] }
    
    {
      :statistics => statistics,
      :ranked => ranked,
      :by_type => by_type
    }
  end

  # Fix the Ruby singleton method 'sort_by_rating' on this Robot instance.
  # 
  # Robot's overall goal: Analyze landmark data. The input is an Array of Hashes, each with keys :name (String), :type (String), :duration (Integer), :rating (Float). Return a Hash with three keys: :statistics (a Hash with :avg_rating, :avg_duration, :total_duration, :count), :ranked (the landmarks Array sorted by :rating descending), :by_type (a Hash grouping landmarks by :type)
  # Generated capabilities on this object: [:calculate_statistics, :sort_by_rating, :group_by_type, :execute_task]
  # 
  # Current source code of 'sort_by_rating':
  # def sort_by_rating(landmarks)
  #   landmarks.sort_by { |landmark| -landmark[:rating] || 0 }
  # end
  # 
  # Runtime error:
  #   NoMethodError: undefined method 'sort_by' for nil
  # 
  # Backtrace (top 5):
  #   (eval at /Users/dewayne/sandbox/git_repos/madbomber/self_agency/lib/self_agency.rb:265):2:in 'sort_by_rating'
  #     (eval at /Users/dewayne/sandbox/git_repos/madbomber/self_agency/lib/self_agency.rb:265):3:in 'execute_task'
  #     /Users/dewayne/sandbox/git_repos/madbomber/self_agency/examples/12_autonomous_robots/robot.rb:72:in 'Robot#perform_task'
  #     ./main.rb:102:in '<main>'
  # 
  # This method takes no external input.
  # 
  # Produce a corrected version of this method that avoids the error.
  # Keep the same method name and signature. Only define this one method.
  # Fix the bug while preserving the method's intent.
  def sort_by_rating(landmarks)
    return {
      :statistics => {
        :average_rating => 0.0,
        :average_duration => 0.0,
        :total_duration => 0,
        :count => 0
      },
      :ranked => [],
      :by_type => {}
    } if landmarks.nil? || landmarks.empty?

    total_rating = 0.0
    total_duration = 0
    count = landmarks.length

    landmarks.each do |landmark|
      total_rating += landmark[:rating] || 0.0
      total_duration += landmark[:duration] || 0
    end

    average_rating = count > 0 ? total_rating / count : 0.0
    average_duration = count > 0 ? total_duration.to_f / count : 0.0

    ranked = landmarks.sort_by { |landmark| -(landmark[:rating] || 0.0) }

    by_type = ranked.group_by { |landmark| landmark[:type] }

    {
      :statistics => {
        :average_rating => average_rating,
        :average_duration => average_duration,
        :total_duration => total_duration,
        :count => count
      },
      :ranked => ranked,
      :by_type => by_type
    }
  end

  # def group_by_type(landmarks) -> Hash
  #   Groups an array of landmark hashes by their type.
  #   Parameters: landmarks (Array[Hash]) - array of landmark data hashes
  #   Returns: Hash with type names as keys and Arrays of landmark hashes as values
  #   Algorithm:
  #     1. Initialize an empty Hash result
  #     2. Iterate through each landmark in landmarks array
  #     3. For each landmark, get the :type key value
  #     4. If result has a key for this type, append landmark to that array
  #     5. Otherwise, create new array with landmark as first element
  #     6. Return the grouped result hash
  def group_by_type(landmarks)
    result = {}
    landmarks.each do |landmark|
      type = landmark[:type]
      if result.key?(type)
        result[type] << landmark
      else
        result[type] = [landmark]
      end
    end
    result
  end

  # An instance method named 'execute_task' that orchestrates the following
  # goal: Analyze landmark data. The input is an Array of Hashes, each with keys :name (String), :type (String), :duration (Integer), :rating (Float). Return a Hash with three keys: :statistics (a Hash with :avg_rating, :avg_duration, :total_duration, :count), :ranked (the landmarks Array sorted by :rating descending), :by_type (a Hash grouping landmarks by :type)
  # 
  # It takes one parameter (input) which is the data passed in from a previous stage.
  # 
  # Available helper methods on this object: calculate_statistics, sort_by_rating, group_by_type
  # 
  # Call the helper methods in whatever order makes sense to accomplish the goal.
  # Return the final result. Do NOT define the helper methods — they already exist.
  # Only define the execute_task method itself.
  def execute_task(input)
    statistics = calculate_statistics(input)
    ranked = sort_by_rating(input)
    by_type = group_by_type(input)
    
    {
      :statistics => statistics,
      :ranked => ranked,
      :by_type => by_type
    }
  end
end
