# frozen_string_literal: true

require_relative "robot"

class Collector < Robot
  # Fix the Ruby singleton method 'generate_city_landmarks' on this Robot instance.
  # 
  # Robot's overall goal: Return an Array of 8 Hashes representing fictional city landmarks. Each Hash has Symbol keys :name (String), :type (String, e.g. 'museum'), :duration (Integer, 30..180 minutes), :rating (Float, 1.0..5.0). Do NOT wrap the Array in an outer Hash.
  # Generated capabilities on this object: [:generate_city_landmarks, :random_landmark_name, :random_landmark_type, :random_duration, :random_rating, :execute_task]
  # 
  # Current source code of 'generate_city_landmarks':
  # def generate_city_landmarks(count)
  #   nouns = ["Tower", "Park", "Museum", "Garden", "Library", "Theater", "Stadium", "Bridge", "Clock", "Market"]
  #   landmark_types = ["Historical", "Natural", "Cultural", "Recreational", "Educational", "Entertainment", "Religious", "Commercial"]
  #   
  #   result = []
  #   count.times do
  #     name = "#{nouns.sample} #{nouns.sample}"
  #     type = landmark_types.sample
  #     duration = rand(151) + 30
  #     rating = (rand(41) * 0.1 + 1.0).round(1)
  #     
  #     result << {
  #       name: name,
  #       type: type,
  #       duration: duration,
  #       rating: rating
  #     }
  #   end
  #   
  #   result
  # end
  # 
  # Runtime error:
  #   ArgumentError: wrong number of arguments (given 0, expected 1)
  # 
  # Backtrace (top 5):
  #   (eval at /Users/dewayne/sandbox/git_repos/madbomber/self_agency/lib/self_agency.rb:224):1:in 'generate_city_landmarks'
  #     (eval at /Users/dewayne/sandbox/git_repos/madbomber/self_agency/lib/self_agency.rb:224):2:in 'execute_task'
  #     /Users/dewayne/sandbox/git_repos/madbomber/self_agency/examples/12_autonomous_robots/robot.rb:70:in 'Robot#perform_task'
  #     ./main.rb:94:in '<main>'
  # 
  # This method takes no external input.
  # 
  # Produce a corrected version of this method that avoids the error.
  # Keep the same method name and signature. Only define this one method.
  # Fix the bug while preserving the method's intent.
  def generate_city_landmarks
    nouns = ["Tower", "Park", "Museum", "Garden", "Bridge", "Market", "Theater", "Statue", "Pool", "Cathedral"]
    types = ["Historical", "Natural", "Cultural", "Recreational", "Architectural", "Religious", "Entertainment", "Educational"]
    
    landmarks = []
    8.times do
      landmark = {}
      landmark[:name] = "#{nouns.sample} #{types.sample}"
      landmark[:type] = types.sample
      landmark[:duration] = rand(151) + 30
      landmark[:rating] = (rand(41) * 0.1 + 1.0).round(1)
      landmarks << landmark
    end
    
    landmarks
  end

  # random_landmark_name
  #   Parameters:
  #     
  #   Returns: String
  #   Algorithm:
  #     - Define arrays of adjectives and nouns
  #     - Select random adjective and noun
  #     - Concatenate them with space separator
  #     - Return combined string
  def random_landmark_name
    adjectives = ["Ancient", "Mystic", "Grand", "Hidden", "Golden", "Secret", "Crimson", "Silver", "Floating", "Whispering", "Crystalline", "Enchanted"]
    nouns = ["Mountain", "Forest", "River", "Castle", "Valley", "Cave", "Lake", "Tower", "Garden", "Waterfall", "Bridge", "Temple"]
    
    adjective = adjectives.sample
    noun = nouns.sample
    
    "#{adjective} #{noun}"
  end

  # random_landmark_type
  #   Parameters:
  #     
  #   Returns: String
  #   Algorithm:
  #     - Define array of landmark types
  #     - Select and return random type from array
  def random_landmark_type
    landmark_types = ["lighthouse", "statue", "bridge", "tower", "monument", "obelisk", "arch", "fountain", "palace", "ruins"]
    landmark_types.sample
  end

  # random_duration
  #   Parameters:
  #     
  #   Returns: Integer
  #   Algorithm:
  #     - Generate random integer between 30 and 180 inclusive
  #     - Return integer
  def random_duration
    rand(30..180)
  end

  # random_rating
  #   Parameters:
  #     
  #   Returns: Float
  #   Algorithm:
  #     - Generate random float between 1.0 and 5.0 with one decimal place
  #     - Return float
  def random_rating
    rand(1.0..5.0).round(1)
  end

  # An instance method named 'execute_task' that orchestrates the following
  # goal: Return an Array of 8 Hashes representing fictional city landmarks. Each Hash has Symbol keys :name (String), :type (String, e.g. 'museum'), :duration (Integer, 30..180 minutes), :rating (Float, 1.0..5.0). Do NOT wrap the Array in an outer Hash.
  # 
  # It takes no parameters.
  # 
  # Available helper methods on this object: generate_city_landmarks, random_landmark_name, random_landmark_type, random_duration, random_rating
  # 
  # Call the helper methods in whatever order makes sense to accomplish the goal.
  # Return the final result. Do NOT define the helper methods — they already exist.
  # Only define the execute_task method itself.
  def execute_task
    generate_city_landmarks
  end
end
