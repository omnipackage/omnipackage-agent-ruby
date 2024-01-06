# frozen_string_literal: true

require 'omnipackage_agent/build/runner'
require 'omnipackage_agent/build/config'
require 'omnipackage_agent/extract_version'
require 'omnipackage_agent/distro'
require 'omnipackage_agent/arch'

module OmnipackageAgent
  class Build
    attr_reader :logger, :config, :terminator

    def initialize(config:, logger:, terminator: nil)
      @config = config
      @logger = logger
      @terminator = terminator
    end

    def call(source_path, distros: nil)
      build_config = ::OmnipackageAgent::Build::Config.new(source_path)

      job_variables = {
        version: ::OmnipackageAgent::ExtractVersion.new(build_config, source_path).call
      }

      distros_build_configs = build_config[:builds].select do |i|
        distro_id = i.fetch(:distro)
        ::OmnipackageAgent::Distro.new(distro_id).arch == ::OmnipackageAgent::ARCH && (distros.nil? || distros.include?(distro_id))
      end

      distros_build_configs.shuffle.map { |dbc| build_for_distro(dbc, source_path, job_variables) }.compact
    end

    private

    def build_for_distro(distro_build_config, source_path, job_variables)
      ::OmnipackageAgent::Build::Runner.new(
        build_conf:    distro_build_config,
        config:        config,
        logger:        logger,
        terminator:    terminator,
        source_path:   source_path,
        job_variables: job_variables
      ).call
    end
  end
end
