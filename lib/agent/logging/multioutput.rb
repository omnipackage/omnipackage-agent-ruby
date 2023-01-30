# frozen_string_literal: true

module Agent
  module Logging
    class Multioutput
      attr_reader :outputs

      def initialize(*outputs)
        @outputs = outputs
      end

      def write(message)
        outputs.each { |o| o.write(message) }
      end

      def close
        outputs.each(&:close)
      end
    end
  end
end
