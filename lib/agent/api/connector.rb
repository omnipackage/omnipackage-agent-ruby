# frozen_string_literal: true

require 'agent/api/client'

module Agent
  module Api
    class Connector
      def initialize(apihost, apikey)
        @thread = ::Thread.new do
          mainloop(::Agent::Api::Client.new(apihost, apikey))
        end
      end

      def join
        thread.join
      end

      private

      attr_reader :thread

      def mainloop(client)
        loop do
          # read queue
          # send
          # receive and put into another queue
          sleep 20
        end
      end
    end
  end
end
