# frozen_string_literal: true

require 'agent/api/state'

module Agent
  module Api
    class Scheduler
      def initialize(logger, queue)
        @mutex = ::Mutex.new
        @logger = logger
        @queue = queue
        recharge!
      end

      def call(payload) # rubocop: disable Metrics/MethodLength
        case
        when state.idle? && payload['command'] == 'start'
          start!(payload)
        when state.busy? && payload['command'] == 'stop'
          stop!
        when state.finished?
        end
      rescue ::StandardError => e
        logger.error("scheduling error: #{e.message}")
      end

      def state
        mutex.synchronize do
          @state
        end
      end

      private

      def start!(payload)
        logger.info('starting build')
        logger.debug(payload)

        mutex.synchronize do
          @state = ::Agent::Api::State.new('busy', agent_task_id: payload.fetch('agent_task_id'))
        end
        queue.push(state)
      end

      def stop!
        logger.info('stopping build')
      end

      def finish!
        mutex.synchronize do
          @state = ::Agent::Api::State.new('finished', agent_task_id: state.agent_task_id)
        end
        queue.push(state)
      end

      def recharge!
        mutex.synchronize do
          @state = ::Agent::Api::State.new('idle')
        end
        queue.push(state)
      end

      attr_reader :mutex, :logger, :queue
    end
  end
end
