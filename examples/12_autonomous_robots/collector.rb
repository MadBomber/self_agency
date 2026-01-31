# frozen_string_literal: true

require_relative "robot"

class Collector < Robot
  # def generate_city_landmarks
  #   landmarks = []
  #   types = ['museum', 'park', 'monument', 'theater', 'zoo', 'library', 'observatory', 'bridge']
  #   names = ['Grand Gallery', 'Skyward Plaza', 'Heritage Tower', 'Moonlit Theater', 'Wildlife Reserve', 'Knowledge Hall', 'Starwatch Point', 'Riverside Arch']
  #   8.times do |i|
  #     landmark = {
  #       name: names[i],
  #       type: types[i],
  #       duration: rand(30..180),
  #       rating: (rand * 4.0 + 1.0).round(1)
  #     }
  #     landmarks << landmark
  #   end
  #   landmarks
  # end
  def generate_city_landmarks
    landmarks = []
    types = ['museum', 'park', 'monument', 'theater', 'zoo', 'library', 'observatory', 'bridge']
    names = ['Grand Gallery', 'Skyward Plaza', 'Heritage Tower', 'Moonlit Theater', 'Wildlife Reserve', 'Knowledge Hall', 'Starwatch Point', 'Riverside Arch']
    
    8.times do |i|
      landmark = {}
      landmark[:name] = names[i]
      landmark[:type] = types[i]
      landmark[:duration] = rand(30..180)
      landmark[:rating] = (rand * 4.0 + 1.0).round(1)
      landmarks << landmark
    end
    
    landmarks
  end

  # An instance method named 'execute_task' that orchestrates the following
  # goal: Return an Array of 8 Hashes representing fictional city landmarks. Each Hash has Symbol keys :name (String), :type (String, e.g. 'museum'), :duration (Integer, 30..180 minutes), :rating (Float, 1.0..5.0). Do NOT wrap the Array in an outer Hash.
  # 
  # It takes no parameters.
  # 
  # Available helper methods on this object: generate_city_landmarks
  # 
  # Call the helper methods in whatever order makes sense to accomplish the goal.
  # Return the final result. Do NOT define the helper methods — they already exist.
  # Only define the execute_task method itself.
  def execute_task
    generate_city_landmarks
  end
end
