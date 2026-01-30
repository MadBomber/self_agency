# frozen_string_literal: true

module SelfAgency
  private

  # Send a prompt to the configured LLM using a named template.
  # Returns the response content string, or nil on failure.
  def self_agency_ask_with_template(template_name, **variables)
    cfg  = SelfAgency.configuration
    chat = RubyLLM.chat(model: cfg.model, provider: cfg.provider)
    response = chat.with_template(template_name, variables).complete
    response.content
  rescue => e
    nil
  end

  # Pass 1: rewrite the user's casual prompt into a precise technical spec.
  def self_agency_shape(raw_prompt, scope)
    scope_instruction = case scope
    when :instance  then "This will be an instance method available on all instances of the class."
    when :singleton then "This will be a singleton method on one specific object instance only."
    when :class     then "This will be a class method (def self.method_name)."
    end

    self_agency_ask_with_template(
      :shape,
      class_name:        self.class.name,
      ivars:             instance_variables.join(", "),
      methods:           (self.class.public_instance_methods(false) - Object.public_instance_methods).sort.join(", "),
      scope_instruction: scope_instruction,
      raw_prompt:        raw_prompt
    )
  end

  # Build a Hash of introspected class context for the generate template.
  def self_agency_generation_vars
    {
      class_name: self.class.name,
      ivars:      instance_variables.join(", "),
      methods:    (self.class.public_instance_methods(false) - Object.public_instance_methods).sort.join(", ")
    }
  end
end
