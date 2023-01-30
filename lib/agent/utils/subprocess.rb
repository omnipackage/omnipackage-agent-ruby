# frozen_string_literal: true

require 'open3'

module Agent
  module Utils
    class Subprocess
      attr_reader :logger

      def initialize(logger: ::Agent.logger)
        @logger = logger
      end

      def execute(cli, &block)
        logger.info("starting child process: #{cli}")
        exit_status = nil
        ::Open3.popen2e(cli) do |_stdin, stdout_and_stderr, wait_thr|
          pid = wait_thr.pid
          logger.debug("started child process with pid #{pid}")

          stdout_and_stderr.each(&block) if block

          exit_status = wait_thr.value
          logger.debug("finished child process #{exit_status}")
        end
        exit_status
      end
    end
  end
end
