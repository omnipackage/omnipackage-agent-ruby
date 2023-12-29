# frozen_string_literal: true

require 'stringio'

module OmnipackageAgent
  module Logging
    class Stdout2 < ::StringIO
      def initialize(max_length = 15_000_000)
        @mutex = ::Mutex.new
        @max_length = max_length
        super(::String.new, 'a+')
      end

      def dequeue
        rewind
        string = read
        clear
        string
      end

      def clear
        truncate(0)
      end

      def write(*args)
        clear if length > max_length

        mutex.synchronize { super(*args) }
      end

      def read(*args)
        mutex.synchronize { super(*args) }
      end

      def close
        mutex.synchronize { super }
      end

      def rewind
        mutex.synchronize { super }
      end

      def truncate(*args)
        mutex.synchronize { super(*args) }
      end

      private

      attr_reader :mutex, :max_length
    end
  end
end
