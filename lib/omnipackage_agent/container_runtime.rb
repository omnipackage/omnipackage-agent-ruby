# frozen_string_literal: true

require 'omnipackage_agent/utils/subprocess'

module OmnipackageAgent
  class ContainerRuntime
    attr_reader :logger, :subprocess, :config

    def initialize(logger:, config:, terminator:)
      @logger = logger
      @config = config
      @subprocess = ::OmnipackageAgent::Utils::Subprocess.new(logger: logger, terminator: terminator)
    end

    def execute(cli, &block)
      subprocess.execute("#{config.container_runtime} #{cli}", &block)
    end
  end
end
