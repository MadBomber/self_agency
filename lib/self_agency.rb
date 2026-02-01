# frozen_string_literal: true

require "method_source"
require_relative "self_agency/version"
require_relative "self_agency/errors"
require_relative "self_agency/configuration"
require_relative "self_agency/sandbox"
require_relative "self_agency/validator"
require_relative "self_agency/generator"
require_relative "self_agency/saver"

# SelfAgency — a standalone mixin that gives any class the ability to
# generate and install methods at runtime via an LLM.
#
# Usage:
#   SelfAgency.configure do |config|
#     config.provider = :ollama
#     config.model    = "qwen3-coder:30b"
#     config.api_base = "http://localhost:11434/v1"
#   end
#
#   class Foo
#     include SelfAgency
#   end
#
#   foo = Foo.new
#   method_name = foo._("an instance method to add two integers, return the result")
#   foo.send(method_name, 1, 1) #=> 2
#
module SelfAgency
  # ---------------------------------------------------------------------------
  # Class-level API — added to including classes via self.included
  # ---------------------------------------------------------------------------

  module ClassMethods
    # Return the generated source code for +method_name+, or nil if unavailable.
    # Checks LLM-generated source first, then falls back to method_source.
    # LLM-generated methods include the original description as a comment header.
    def _source_for(method_name)
      name = method_name.to_sym
      if (code = self_agency_class_sources[name])
        self_agency_comment_header(self_agency_class_descriptions[name]) + code
      else
        self_agency_file_source(instance_method(name))
      end
    rescue NameError, MethodSource::SourceNotFoundError
      nil
    end

    def self_agency_class_sources
      @self_agency_class_sources ||= {}
    end

    def self_agency_class_descriptions
      @self_agency_class_descriptions ||= {}
    end

    private

    def self_agency_comment_header(description)
      return "" unless description
      description.lines.map { |line| "# #{line.chomp}\n" }.join
    end

    def self_agency_file_source(meth)
      comment = meth.comment.to_s
      source  = meth.source
      comment.empty? ? source : comment + source
    end
  end

  # ---------------------------------------------------------------------------
  # Public instance API
  # ---------------------------------------------------------------------------

  # Generate and install a method described by +description+.
  #
  # @param description [String] natural-language description of the method
  # @param scope [Symbol] :instance, :singleton, or :class
  # @return [Array<Symbol>] the names of the newly defined methods
  # @raise [GenerationError]  if the LLM returns nil
  # @raise [ValidationError]  if the generated code fails validation
  # @raise [SecurityError]    if the generated code contains dangerous patterns
  def _(description, scope: :instance)
    SelfAgency.ensure_configured!

    shaped = self_agency_shape(description, scope)
    raise GenerationError, "Prompt shaping failed (LLM returned nil)" unless shaped

    raw = self_agency_ask_with_template(:generate, **self_agency_generation_vars.merge(shaped_spec: shaped))
    raise GenerationError, "Code generation failed (LLM returned nil)" unless raw

    code = self_agency_sanitize(raw)
    self_agency_validate!(code)
    self_agency_eval(code, scope)

    method_blocks = self_agency_split_methods(code)
    method_names = method_blocks.map do |name, block|
      self_agency_sources[name] = block
      self_agency_descriptions[name] = description
      self.class.self_agency_class_sources[name] = block
      self.class.self_agency_class_descriptions[name] = description
      on_method_generated(name, scope, block)
      name
    end

    method_names
  end

  alias_method :self_agency_generate, :_

  # Return the generated source code for +method_name+, or nil if unavailable.
  # Checks LLM-generated source first, then falls back to method_source.
  # LLM-generated methods include the original description as a comment header.
  def _source_for(method_name)
    name = method_name.to_sym
    if (code = self_agency_sources[name])
      self_agency_comment_header(self_agency_descriptions[name]) + code
    else
      self_agency_file_source(method(name))
    end
  rescue NameError, MethodSource::SourceNotFoundError
    nil
  end

  # Save the object's generated methods as a subclass in a Ruby source file.
  #
  # @param as [String, Symbol] the subclass name (snake_case is converted to CamelCase)
  # @param path [String, nil] output file path (defaults to snake_cased name + .rb)
  # @return [String] the path written to
  # @raise [ArgumentError] if as: is not a String or Symbol
  # @raise [Error] if there are no generated methods to save
  def _save!(as:, path: nil)
    raise ArgumentError, "as: must be a String or Symbol" unless as.is_a?(String) || as.is_a?(Symbol)
    raise Error, "no generated methods to save" if self_agency_sources.empty?

    class_name  = self_agency_to_class_name(as)
    file_path   = path || "#{self_agency_to_snake_case(class_name)}.rb"
    parent_name = self.class.name
    raise Error, "cannot save anonymous class" unless parent_name

    parent_source = Object.const_source_location(parent_name)&.first

    require_path = if parent_source
      self_agency_relative_require(file_path, parent_source)
    end

    source = self_agency_build_subclass_source(
      class_name, parent_name, require_path,
      self_agency_sources, self_agency_descriptions
    )

    File.write(file_path, source)
    file_path
  end

  # Override in your class to persist or log generated methods.
  def on_method_generated(method_name, scope, code)
    # no-op by default
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------
  private

  def self_agency_comment_header(description)
    return "" unless description
    description.lines.map { |line| "# #{line.chomp}\n" }.join
  end

  def self_agency_file_source(meth)
    comment = meth.comment.to_s
    source  = meth.source
    comment.empty? ? source : comment + source
  end

  # Lazily initialized Hash storing generated source code keyed by method name.
  def self_agency_sources
    @self_agency_sources ||= {}
  end

  def self_agency_descriptions
    @self_agency_descriptions ||= {}
  end

  # Split code containing one or more method definitions into
  # an Array of [method_name_symbol, method_source_string] pairs.
  def self_agency_split_methods(code)
    blocks = code.scan(/^(def\s+(?:self\.)?\w+[?!=]?.*?^end)/m)
    blocks.map do |match|
      block = match[0]
      name  = block.match(/\bdef\s+(self\.)?(\w+[?!=]?)/)[2].to_sym
      [name, block]
    end
  end

  # Evaluate the code inside a sandboxed anonymous module.
  def self_agency_eval(code, scope)
    sandbox_mod = Module.new { include SelfAgency::Sandbox }

    case scope
    when :instance
      sandbox_mod.module_eval(code)
      self.class.prepend(sandbox_mod)
    when :singleton
      sandbox_mod.module_eval(code)
      singleton_class.prepend(sandbox_mod)
    when :class
      class_code = code.sub(/\bdef\s+self\./, "def ")
      sandbox_mod.module_eval(class_code)
      self.class.singleton_class.prepend(sandbox_mod)
    else
      raise ValidationError, "unknown scope: #{scope.inspect}"
    end
  end
end
