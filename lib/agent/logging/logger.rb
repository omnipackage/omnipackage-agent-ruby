# frozen_string_literal: true

require 'agent/logging/formatter'
require 'agent/logging/multioutput'

module Agent
  module Logging
    class Logger < ::Logger
      def initialize(outputs: [$stdout])
        @outputs = outputs
        super(::Agent::Logging::Multioutput.new(*outputs), formatter: ::Agent::Logging::Formatter.new)
      end

      def add_outputs(*outputs)
        self.class.new(outputs: @outputs + outputs)
      end
    end
  end
end
