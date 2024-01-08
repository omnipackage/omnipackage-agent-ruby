# frozen_string_literal: true

require 'omnipackage_agent/api/state'
require 'omnipackage_agent/api/task'
require 'omnipackage_agent/build/output'

module OmnipackageAgent
  module Api
    class Scheduler
      def initialize(config:, logger:, queue:, downloader:)
        @mutex = ::Mutex.new
        @logger = logger
        @queue = queue
        @downloader = downloader
        @config = config
        recharge!
      end

      def call(payload) # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
        case # rubocop: disable Style/EmptyCaseCondition
        when state.idle? && payload['command'] == 'start'
          task = ::OmnipackageAgent::Api::Task.new(
            id:           payload.fetch('task').fetch('id'),
            tarball_url:  payload.fetch('task').fetch('sources_tarball_url'),
            upload_url:   payload.fetch('task').fetch('upload_artefact_url'),
            distros:      payload.fetch('task').fetch('distros'),
            downloader:   downloader,
            logger:       logger,
            config:       config
          )
          start!(task)
        when state.busy? && payload['command'] == 'stop'
          stop!
        when state.finished?
          recharge!
        end
      rescue ::StandardError => e
        logger.error("scheduling error: #{e.message}")
      end

      def state_serialize # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
        mutex.synchronize do
          result = state.to_hash
          if state.task
            result[:livelog] = state.task.read_log
            if state.task.build_outputs
              result[:stats] = {
                total_time:     state.task.build_outputs.sum(&:total_time),
                lockwait_time:  state.task.build_outputs.sum(&:lockwait_time)
              }
            end
          end
          result
        end
      end

      private

      attr_reader :mutex, :logger, :queue, :downloader, :state, :config

      def finalize(task)
        finish!(task)
      end

      def start!(task)
        logger.info("starting build, task #{task.to_hash}")
        mutex.synchronize do
          @state = ::OmnipackageAgent::Api::State.new('busy', task: task)
        end

        task.start(&method(:finalize))
        queue.push(state)
      end

      def stop!
        logger.info('stopping build')
        mutex.synchronize do
          @state.task.stop
        end
      end

      def finish!(task)
        logger.info("finishing build, task #{task.to_hash}")
        mutex.synchronize do
          @state = ::OmnipackageAgent::Api::State.new('finished', task: task)
        end
        queue.push(state)
      end

      def recharge!
        logger.info('recharging')
        mutex.synchronize do
          @state = ::OmnipackageAgent::Api::State.new('idle')
        end
        queue.push(state)
      end
    end
  end
end
