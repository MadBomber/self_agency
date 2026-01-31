# frozen_string_literal: true

require "pathname"

module SelfAgency
  private

  # Convert a String or Symbol to a CamelCase class name.
  #   :collector       → "Collector"
  #   "weather_analyst" → "WeatherAnalyst"
  #   "WeatherAnalyst"  → "WeatherAnalyst"
  def self_agency_to_class_name(value)
    str = value.to_s
    return str if str.match?(/\A[A-Z]/)

    str.split("_").map(&:capitalize).join
  end

  # Convert a CamelCase class name to snake_case.
  #   "WeatherAnalyst" → "weather_analyst"
  def self_agency_to_snake_case(class_name)
    class_name.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
  end

  # Compute the require_relative path from the output file to the parent source.
  def self_agency_relative_require(output_path, source_path)
    output_dir = File.dirname(File.expand_path(output_path))
    source_abs = File.expand_path(source_path)

    Pathname.new(source_abs)
      .relative_path_from(Pathname.new(output_dir))
      .to_s
      .sub(/\.rb\z/, "")
  end

  # Build the Ruby source string for a subclass file.
  def self_agency_build_subclass_source(class_name, parent_class, require_path, sources, descriptions)
    output = +"# frozen_string_literal: true\n\n"
    output << "require_relative \"#{require_path}\"\n\n" if require_path
    output << "class #{class_name} < #{parent_class}\n"

    sources.each_with_index do |(name, code), index|
      output << "\n" if index > 0

      if (desc = descriptions[name])
        desc.each_line { |line| output << "  # #{line.chomp}\n" }
      end

      code.each_line do |line|
        if line.chomp.empty?
          output << "\n"
        else
          output << "  #{line}"
        end
      end
      output << "\n" unless output.end_with?("\n")
    end

    output << "end\n"
    output
  end
end
