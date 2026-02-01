# frozen_string_literal: true

module SelfAgency
  # Static-analysis patterns that must never appear in generated code
  DANGEROUS_PATTERNS = /
    \b(system|exec|spawn|fork|abort|exit)\b |
    `[^`]*`                                 |
    %x\{                                    |
    %x\[                                    |
    %x\(                                    |
    \bFile\.\b                              |
    \bIO\.\b                                |
    \bKernel\.\b                            |
    \bOpen3\.\b                             |
    \bProcess\.\b                           |
    \brequire\b                             |
    \bload\b                                |
    \b__send__\b                            |
    \beval\b                                |
    \bsend\b                                |
    \bpublic_send\b                         |
    \bmethod\s*\(                           |
    \bconst_get\b                           |
    \bclass_eval\b                          |
    \bmodule_eval\b                         |
    \binstance_eval\b                       |
    \binstance_variable_set\b               |
    \binstance_variable_get\b               |
    \bdefine_method\b                       |
    \bBinding\b                             |
    \bBasicObject\b                         |
    \bremove_method\b                       |
    \bundef_method\b
  /x

  private

  # Strip markdown fences, <think> blocks, and leading/trailing whitespace.
  def self_agency_sanitize(raw)
    text = raw.to_s.strip
    text = text.sub(/\A```\w*\n?/, "").sub(/\n?```\s*\z/, "")
    text = text.gsub(/<think>.*?<\/think>/m, "")
    text.strip
  end

  # Validate the sanitized code. Raises on problems.
  def self_agency_validate!(code)
    raise ValidationError.new("code is empty", generated_code: code) if code.empty?
    unless code.match?(/\bdef\s+\S+.*?\bend\b/m)
      raise ValidationError.new("missing def...end structure", generated_code: code)
    end
    if (match = code.match(DANGEROUS_PATTERNS))
      raise SecurityError.new(
        "dangerous pattern detected: #{match[0].strip}",
        matched_pattern: match[0].strip,
        generated_code:  code
      )
    end

    RubyVM::InstructionSequence.compile(code)
  rescue SyntaxError => e
    raise ValidationError.new("syntax error: #{e.message}", generated_code: code)
  end
end
