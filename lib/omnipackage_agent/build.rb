# frozen_string_literal: true

require 'omnipackage_agent/build/runner'
require 'omnipackage_agent/build/config'
require 'omnipackage_agent/extract_version'
require 'omnipackage_agent/distro'
require 'omnipackage_agent/arch'

module OmnipackageAgent
  class Build
    attr_reader :logger, :config

    def initialize(config:, logger:)
      @config = config
      @logger = logger
    end

    def call(source_path, distros: nil, terminator: nil) # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
      build_config = ::OmnipackageAgent::Build::Config.new(source_path)

      job_variables = {
        version: ::OmnipackageAgent::ExtractVersion.new(build_config, source_path).call
      }

      build_config[:builds].select do |i|
        distro_id = i.fetch(:distro)
        ::OmnipackageAgent::Distro.new(distro_id).arch == ::OmnipackageAgent::ARCH && (distros.nil? || distros.include?(distro_id))
      end.shuffle.map do |distro_build_config| # rubocop: disable Style/MultilineBlockChain
        ::OmnipackageAgent::Build::Runner.new(
          build_conf:    distro_build_config,
          config:        config,
          logger:        logger,
          terminator:    terminator,
          source_path:   source_path,
          job_variables: job_variables
        ).call
      end.compact
    end
  end
end
