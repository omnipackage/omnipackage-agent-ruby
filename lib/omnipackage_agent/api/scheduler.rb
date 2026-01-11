# frozen_string_literal: true

require 'omnipackage_agent/api/state'
require 'omnipackage_agent/api/task'
require 'omnipackage_agent/build/output'
require 'omnipackage_agent/build/limits'
require 'omnipackage_agent/build/secrets'

module OmnipackageAgent
  module Api
    class Scheduler
      def initialize(config:, logger:, queue:, downloader:)
        @mutex = ::Mutex.new
        @logger = logger
        @queue = queue
        @downloader = downloader
        @config = config
        @start_time = current_time_monotonic
        recharge!
      end

      def call(payload) # rubocop: disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        case # rubocop: disable Style/EmptyCaseCondition
        when state.idle? && payload['command'] == 'start'
          task = ::OmnipackageAgent::Api::Task.new(
            id:                 payload.fetch('task').fetch('id'),
            tarball_url:        payload.fetch('task').fetch('sources_tarball_url'),
            upload_url:         payload.fetch('task').fetch('upload_artefact_url'),
            distros:            payload.fetch('task').fetch('distros'),
            build_config_path:  payload.fetch('task').fetch('build_config_path', nil),
            limits:             ::OmnipackageAgent::Build::Limits.deserialize(payload.fetch('task')['limits']),
            secrets:            ::OmnipackageAgent::Build::Secrets.deserialize(payload.fetch('task')['secrets']),
            downloader:         downloader,
            logger:             logger,
            config:             config
          )
          start!(task)
        when state.busy? && payload['command'] == 'stop'
          stop!
        when state.finished?
          recharge!
        when state.idle? && single_shot_expired?
          logger.warn('single-shot wait timeout expired')
          queue.push('quit')
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

      attr_reader :mutex, :logger, :queue, :downloader, :state, :config, :start_time

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
        return unless config.single_shot

        logger.warn('single-shot task finished')
        queue.push('quit')
      end

      def recharge!
        logger.info('recharging')
        mutex.synchronize do
          @state = ::OmnipackageAgent::Api::State.new('idle')
        end
        queue.push(state)
      end

      def current_time_monotonic
        ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
      end

      def single_shot_expired?
        config.single_shot && config.single_shot_wait_sec < (current_time_monotonic - start_time)
      end
    end
  end
end
