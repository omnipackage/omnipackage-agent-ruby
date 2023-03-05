# frozen_string_literal: true

require 'agent/api/state'
require 'agent/api/task'

module Agent
  module Api
    class Scheduler
      def initialize(logger, queue, apikey:)
        @mutex = ::Mutex.new
        @logger = logger
        @queue = queue
        @apikey = apikey
        recharge!
      end

      def call(payload) # rubocop: disable Metrics/MethodLength
        case
        when state.idle? && payload['command'] == 'start'
          task = ::Agent::Api::Task.from_hash(payload.fetch('task'))
          start!(task)
        when state.busy? && payload['command'] == 'stop'
          stop!
        when state.finished?
          # send artefacts etc...
          recharge!
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

      def start!(task)
        logger.info("starting build, task #{task.to_hash}")
        mutex.synchronize do
          @state = ::Agent::Api::State.new('busy', task: task)
        end

        task.start(apikey) do |result|
          finish!(task)
        end
        queue.push(state)
      end

      def stop!
        logger.info('stopping build')
      end

      def finish!(task)
        logger.info("finishing build, task #{task.to_hash}")
        mutex.synchronize do
          @state = ::Agent::Api::State.new('finished', task: task)
        end
        queue.push(state)
      end

      def recharge!
        logger.info('recharging')
        mutex.synchronize do
          @state = ::Agent::Api::State.new('idle')
        end
        queue.push(state)
      end

      attr_reader :mutex, :logger, :queue, :apikey
    end
  end
end
