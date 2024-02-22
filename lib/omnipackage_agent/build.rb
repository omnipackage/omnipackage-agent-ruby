# frozen_string_literal: true

require 'omnipackage_agent/build/runner'
require 'omnipackage_agent/build/config'
require 'omnipackage_agent/build/extract_version'
require 'omnipackage_agent/distro'
require 'omnipackage_agent/arch'
require 'omnipackage_agent/build/limits'

module OmnipackageAgent
  class Build
    attr_reader :logger, :config, :terminator, :limits

    def initialize(config:, logger:, limits: nil, terminator: nil)
      @config = config
      @logger = logger
      @terminator = terminator
      @limits = limits || ::OmnipackageAgent::Build::Limits.new
    end

    def call(source_path, distros: nil)
      build_config = ::OmnipackageAgent::Build::Config.new(source_path)

      job_variables = {
        version: ::OmnipackageAgent::Build::ExtractVersion.new(build_config, source_path).call
      }

      distros_build_configs(build_config, distros).shuffle.map { |dbc| build_for_distro(dbc, source_path, job_variables) }.compact
    end

    private

    def distros_build_configs(build_config, distros)
      build_config[:builds].select do |i|
        distro_id = i.fetch(:distro)

        ::OmnipackageAgent::Distro.exists?(distro_id) &&
          ::OmnipackageAgent::Distro.new(distro_id).arch == ::OmnipackageAgent::ARCH &&
          (distros.nil? || distros.include?(distro_id))
      end
    end

    def build_for_distro(distro_build_config, source_path, job_variables)
      return if terminator&.called?

      ::OmnipackageAgent::Build::Runner.new(
        build_conf:    distro_build_config,
        config:        config,
        logger:        logger,
        terminator:    terminator,
        source_path:   source_path,
        job_variables: job_variables.merge(current_time_rfc2822: ::Time.now.strftime('%a, %-d %b %Y %T %z')),
        limits:        limits
      ).call
    end
  end
end
