# frozen_string_literal: true

require 'agent/api/client'
require 'agent/api/client/download'
require 'agent/api/scheduler'
require 'agent/utils/timed_queue'
require 'agent/distro'

module Agent
  module Api
    class Connector
      attr_reader :scheduler

      def initialize(apihost, apikey)
        @logger = ::Agent.logger
        @queue = ::Agent::TimedQueue.new
        @scheduler = ::Agent::Api::Scheduler.new(logger, queue, downloader: ::Agent::Api::Client::Download.new(apikey))
        @thread = ::Thread.new do
          mainloop(::Agent::Api::Client.new(apihost, apikey))
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
            ::Agent::Distro.set_distro_configs!(response.payload['distro_configs']) if response.payload['distro_configs']
            scheduler.call(response.payload)
          else
            logger.error("connector error: #{response.error_message}")
          end
        rescue ::StandardError => e
          logger.error(e.message)
        ensure
          case queue.pop(response&.next_poll_after || rand(30..180))
          when 'quit'
            break
          end
        end
      end
    end
  end
end
