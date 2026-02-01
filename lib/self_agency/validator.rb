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
    raise ValidationError, "code is empty" if code.empty?
    raise ValidationError, "missing def...end structure" unless code.match?(/\bdef\s+\S+.*?\bend\b/m)
    raise SecurityError, "dangerous pattern detected" if code.match?(DANGEROUS_PATTERNS)

    RubyVM::InstructionSequence.compile(code)
  rescue SyntaxError => e
    raise ValidationError, "syntax error: #{e.message}"
  end
end
