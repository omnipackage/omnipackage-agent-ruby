# frozen_string_literal: true

module OmnipackageAgent
  module Api
    class State
      STATES = %w[idle busy finished].freeze
      private_constant :STATES

      attr_reader :state, :task

      def initialize(state, task: nil)
        raise ::ArgumentError, "state must be one of #{STATES}" unless STATES.include?(state)

        @state = state
        @task = task
        freeze
      end

      STATES.each do |s|
        define_method("#{s}?") { state == s }
      end

      def to_hash
        {
          state: state,
          task:  task&.to_hash
        }
      end
    end
  end
end
