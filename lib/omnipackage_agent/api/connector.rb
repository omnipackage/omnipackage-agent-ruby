# frozen_string_literal: true

require 'omnipackage_agent/api/client'
require 'omnipackage_agent/api/client/download'
require 'omnipackage_agent/api/scheduler'
require 'omnipackage_agent/utils/timed_queue'
require 'omnipackage_agent/distro'

module OmnipackageAgent
  module Api
    class Connector
      attr_reader :scheduler

      def initialize(config:, logger:) # rubocop: disable Metrics/MethodLength
        @logger = logger
        @queue = ::OmnipackageAgent::TimedQueue.new
        @scheduler = ::OmnipackageAgent::Api::Scheduler.new(
          logger:     logger,
          queue:      queue,
          config:     config,
          downloader: ::OmnipackageAgent::Api::Client::Download.new(config.apikey)
        )
        @thread = ::Thread.new do
          mainloop(::OmnipackageAgent::Api::Client.new(config.apihost, config.apikey))
        end
      end

      def join
        thread.join
      end

      private

      attr_reader :thread, :logger, :queue

      def mainloop(client) # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
        loop do
          response = client.call(scheduler.state_serialize)
          if response.ok?
            ::OmnipackageAgent::Distro.set_distro_configs!(response.payload['distro_configs']) if response.payload['distro_configs']
            scheduler.call(response.payload)
          else
            logger.error("connector error: #{response.error_message}")
          end
        rescue ::StandardError => e
          logger.error(e.message)
        ensure
          case queue.pop(response&.next_poll_after || rand(30..180))
          when 'quit'
            logger.info('quitting')
            break
          end
        end
      end
    end
  end
end
