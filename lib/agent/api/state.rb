# frozen_string_literal: true

module Agent
  module Api
    class State
      attr_reader :state, :agent_task_id

      def initialize(state, agent_task_id: nil)
        @state = state
        @agent_task_id = agent_task_id
        freeze
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
