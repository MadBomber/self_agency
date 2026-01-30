# frozen_string_literal: true

require_relative "lib/self_agency/version"

Gem::Specification.new do |spec|
  spec.name = "self_agency"
  spec.version = SelfAgency::VERSION
  spec.authors = ["Dewayne VanHoozer"]
  spec.email = ["dewayne@vanhoozer.me"]

  spec.summary = "LLM-powered runtime method generation for Ruby classes"
  spec.description = "A mixin that gives any Ruby class the ability to generate and install methods at runtime via an LLM. Describe what you want in plain English and get a working method back."
  spec.homepage = "https://github.com/madbomber/self_agency"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/madbomber/self_agency"
  spec.metadata["changelog_uri"] = "https://github.com/madbomber/self_agency/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "method_source"
  spec.add_dependency "ruby_llm"
  spec.add_dependency "ruby_llm-template"
end
