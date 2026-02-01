# frozen_string_literal: true

require_relative "robot"

class Collector < Robot
  # def generate_landmark_data
  #   landmarks = []
  #   8.times do |i|
  #     name = "Landmark #{i + 1}"
  #     type = ['museum', 'park', 'bridge', 'tower', 'theater', 'garden', 'statue', 'monument'].sample
  #     duration = rand(30..180)
  #     rating = (rand(100..500).to_f / 100.0).round(1)
  #     landmarks << { name: name, type: type, duration: duration, rating: rating }
  #   end
  #   landmarks
  # end
  def generate_landmark_data
    landmarks = []
    8.times do |i|
      name = "Landmark #{i + 1}"
      type = ['museum', 'park', 'bridge', 'tower', 'theater', 'garden', 'statue', 'monument'].sample
      duration = rand(30..180)
      rating = (rand(100..500).to_f / 100.0).round(1)
      landmark = { name: name, type: type, duration: duration, rating: rating }
      landmarks << landmark
    end
    landmarks
  end

  # Fix the Ruby singleton method 'execute_task' on this Robot instance.
  # 
  # Robot's overall goal: Return an Array of 8 Hashes representing fictional city landmarks. Each Hash has Symbol keys :name (String), :type (String, e.g. 'museum'), :duration (Integer, 30..180 minutes), :rating (Float, 1.0..5.0). Do NOT wrap the Array in an outer Hash.
  # Generated capabilities on this object: [:generate_landmark_data, :execute_task]
  # 
  # Current source code of 'execute_task':
  # def execute_task
  #   landmarks = []
  #   8.times do
  #     data = generate_landmark_data
  #     landmarks << {
  #       name: data[:name],
  #       type: data[:type],
  #       duration: rand(30..180),
  #       rating: rand(1.0..5.0)
  #     }
  #   end
  #   landmarks
  # end
  # 
  # Runtime error:
  #   TypeError: no implicit conversion of Symbol into Integer
  # 
  # Backtrace (top 5):
  #   (eval at /Users/dewayne/sandbox/git_repos/madbomber/self_agency/lib/self_agency.rb:265):6:in 'block in execute_task'
  #     (eval at /Users/dewayne/sandbox/git_repos/madbomber/self_agency/lib/self_agency.rb:265):3:in 'Integer#times'
  #     (eval at /Users/dewayne/sandbox/git_repos/madbomber/self_agency/lib/self_agency.rb:265):3:in 'execute_task'
  #     /Users/dewayne/sandbox/git_repos/madbomber/self_agency/examples/12_autonomous_robots/robot.rb:70:in 'Robot#perform_task'
  #     ./main.rb:94:in '<main>'
  # 
  # This method takes no external input.
  # 
  # Produce a corrected version of this method that avoids the error.
  # Keep the same method name and signature. Only define this one method.
  # Fix the bug while preserving the method's intent.
  def execute_task
    landmarks = []
    8.times do
      data = generate_landmark_data
      landmarks << {
        name: data[:name],
        type: data[:type],
        duration: rand(30..180),
        rating: rand(1.0..5.0)
      }
    end
    landmarks
  end
end
