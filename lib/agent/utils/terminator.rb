# frozen_string_literal: true

module Agent
  module Utils
    class Terminator
      def initialize
        @mutex = ::Mutex.new
        @called = false
      end

      def arm(wait_thr)
        @mutex.synchronize do
          @wait_thr = wait_thr
        end
      end

      def called?
        @called
      end

      def call(timeout = 10) # rubocop: disable Metrics/MethodLength
        return if called?

        @called = true
        return unless @wait_thr

        @mutex.synchronize do
          ::Process.kill('TERM', @wait_thr.pid)
          begin
            ::Timeout.timeout(timeout) do
              @wait_thr.join
            end
          rescue ::Timeout::Error
            ::Process.kill('KILL', @wait_thr.pid)
          end
        end
      ensure
        arm(nil)
      end
    end
  end
end
