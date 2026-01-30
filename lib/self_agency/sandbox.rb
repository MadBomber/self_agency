# frozen_string_literal: true

module SelfAgency
  # Sandbox — shadows dangerous Kernel methods so generated code cannot
  # call them.  Included in an anonymous module that wraps every generated
  # method, placing these shadows ahead of Kernel in Ruby's MRO.
  module Sandbox
    private

    def system(*)  = raise(::SecurityError, "system() blocked by SelfAgency sandbox")
    def exec(*)    = raise(::SecurityError, "exec() blocked by SelfAgency sandbox")
    def spawn(*)   = raise(::SecurityError, "spawn() blocked by SelfAgency sandbox")
    def fork(*)    = raise(::SecurityError, "fork() blocked by SelfAgency sandbox")
    def `(*)       = raise(::SecurityError, "backtick execution blocked by SelfAgency sandbox")
    def open(*)    = raise(::SecurityError, "open() blocked by SelfAgency sandbox")
  end
end
