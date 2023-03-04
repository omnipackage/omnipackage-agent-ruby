# frozen_string_literal: true

module Agent
  module Api
    class State
      STATES = %w[idle busy finished].freeze
      private_constant :STATES

      attr_reader :state, :agent_task_id

      def initialize(state, agent_task_id: nil)
        raise ::ArgumentError, "state must be one of #{STATES}" unless STATES.include?(state)

        @state = state
        @agent_task_id = agent_task_id
        freeze
      end

      STATES.each do |s|
        define_method("#{s}?") { state == s }
      end

      def to_hash
        {
          state:          state,
          agent_task_id:  agent_task_id
        }.freeze
      end
    end
  end
end
