# frozen_string_literal: true

require 'logger'

require 'omnipackage_agent/logging/formatter'
require 'omnipackage_agent/logging/multioutput'

module OmnipackageAgent
  module Logging
    class Logger < ::Logger
      def initialize(outputs: [$stdout])
        @outputs = outputs
        super(::OmnipackageAgent::Logging::Multioutput.new(*outputs), formatter: ::OmnipackageAgent::Logging::Formatter.new)
      end

      def add_outputs(*outputs)
        self.class.new(outputs: @outputs + outputs)
      end
    end
  end
end
