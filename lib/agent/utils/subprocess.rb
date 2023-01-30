# frozen_string_literal: true

require 'open3'

module Agent
  module Utils
    module Subprocess
      extend self

      def execute(cli, &block)
        log("starting child process: #{cli}")
        exit_status = nil
        Open3.popen2e(cli) do |_stdin, stdout_and_stderr, wait_thr|
          pid = wait_thr.pid
          log("started child process with pid #{pid}")

          stdout_and_stderr.each(&block) if block

          exit_status = wait_thr.value
          log("finished child process #{exit_status}")
        end
        exit_status
      end

      private

      def log(msg)
        Agent.logger.debug(msg)
      end
    end
  end
end
