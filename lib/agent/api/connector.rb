# frozen_string_literal: true

require 'agent/api/client'

module Agent
  module Api
    class Connector
      def initialize(apihost, apikey)
        @thread = ::Thread.new do
          mainloop(::Agent::Api::Client.new(apihost, apikey))
        end
        @logger = ::Agent.logger
      end

      def join
        thread.join
      end

      private

      attr_reader :thread, :logger

      def mainloop(client)
        loop do
          response = client.call({state: 'idle'})
          if response.ok?
          else
            logger.error(response.error_message)
          end

          # read queue
          # send
          # receive and put into another queue
          sleep response.next_poll_after
        end
      end
    end
  end
end
