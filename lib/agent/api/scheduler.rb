# frozen_string_literal: true

require 'agent/api/state'
require 'agent/api/task'
require 'agent/build/output'

module Agent
  module Api
    class Scheduler
      def initialize(logger, queue, downloader:)
        @mutex = ::Mutex.new
        @logger = logger
        @queue = queue
        @downloader = downloader
        recharge!
      end

      def call(payload) # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
        case # rubocop: disable Style/EmptyCaseCondition
        when state.idle? && payload['command'] == 'start'
          task = ::Agent::Api::Task.new(
            id:           payload.fetch('task').fetch('id'),
            tarball_url:  payload.fetch('task').fetch('sources_tarball_url'),
            upload_url:   payload.fetch('task').fetch('upload_artefact_url'),
            downloader:   downloader
          )
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

      attr_reader :mutex, :logger, :queue, :downloader

      def finalize(task)
        finish!(task)
      end

      def start!(task)
        logger.info("starting build, task #{task.to_hash}")
        mutex.synchronize do
          @state = ::Agent::Api::State.new('busy', task: task)
        end

        task.start(&method(:finalize))
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
    end
  end
end
