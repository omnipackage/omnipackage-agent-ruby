# frozen_string_literal: true

require 'omnipackage_agent/utils/subprocess'
require 'omnipackage_agent/utils/path'

module OmnipackageAgent
  class ContainerRuntime
    attr_reader :logger, :subprocess, :config

    def initialize(logger:, config:, terminator:)
      @logger = logger
      @config = config
      @subprocess = ::OmnipackageAgent::Utils::Subprocess.new(logger: logger, terminator: terminator)
    end

    def executable
      config.container_runtime
    end

    def execute(cli, lock_key:, &block)
      if lock_key
        ::FileUtils.mkdir_p(config.lockfiles_dir)
        lockfile = ::OmnipackageAgent::Utils::Path.mkpath(config.lockfiles_dir, "#{lock_key.gsub(/[^0-9a-z]/i, '_')}.lock")
        subprocess.execute("flock --no-fork --timeout 21600 #{lockfile} --command '#{cli}'", &block)
      else
        subprocess.execute(cli, &block)
      end
    end
  end
end
