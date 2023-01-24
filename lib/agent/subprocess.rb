# frozen_string_literal: true

require 'open3'

module Agent
  module Subprocess
    extend self

    def execute(cli)
      Agent.logger.debug("starting child process: #{cli}")

      Open3.popen2e(cli) do |_stdin, stdout_and_stderr, wait_thr|
        pid = wait_thr.pid
        Agent.logger.info("started child process with pid #{pid}")

        stdout_and_stderr.each do |line|
          yield(line)
        end

        exit_status = wait_thr.value
        Agent.logger.info("finished child process #{exit_status}")
      end
    end
  end
end
