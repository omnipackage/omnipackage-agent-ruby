# frozen_string_literal: true

require 'open3'

require 'omnipackage_agent/utils/terminator'

module OmnipackageAgent
  module Utils
    class Subprocess
      attr_reader :logger, :terminator

      def initialize(logger:, terminator: nil)
        @logger = logger
        @terminator = terminator
      end

      def execute(cli, timeout_sec: 43_200, term_timeout_sec: 10, &block) # rubocop: disable Metrics/MethodLength
        return if terminator&.called?

        exit_status = nil
        ::Open3.popen2e(cli) do |_stdin, stdout_and_stderr, wait_thr|
          terminator&.arm(wait_thr)
          logger.info("started child process pid #{wait_thr.pid}: #{cli}")

          stdout_and_stderr.each(&block) if block

          wait(wait_thr, timeout_sec, term_timeout_sec)

          exit_status = wait_thr.value
          logger.info("finished child process: #{exit_status}")
        end
        exit_status
      end

      private

      def wait(wait_thr, timeout_sec, term_timeout_sec) # rubocop: disable Metrics/MethodLength
        ::Timeout.timeout(timeout_sec) do
          wait_thr.join
        end
      rescue ::Timeout::Error
        ::Process.kill('TERM', wait_thr.pid)
        begin
          ::Timeout.timeout(term_timeout_sec) do
            wait_thr.join
          end
        rescue ::Timeout::Error
          ::Process.kill('KILL', wait_thr.pid)
        end
      end
    end
  end
end
