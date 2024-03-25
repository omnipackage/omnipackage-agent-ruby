# frozen_string_literal: true

require 'logger'

require 'omnipackage_agent/logging/formatter'
require 'omnipackage_agent/logging/multioutput'

module OmnipackageAgent
  module Logging
    class Logger < ::Logger
      def initialize(outputs: [$stdout], formatter: ::OmnipackageAgent::Logging::Formatter.new)
        @outputs = outputs
        super(::OmnipackageAgent::Logging::Multioutput.new(*outputs), formatter: formatter)
      end

      def add_outputs(*outputs)
        self.class.new(outputs: @outputs + outputs, formatter: formatter)
      end

      def add_filters(*filters)
        self.class.new(outputs: @outputs, formatter: formatter.add_filters(filters))
      end
    end
  end
end
