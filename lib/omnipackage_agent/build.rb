# frozen_string_literal: true

require 'omnipackage_agent/build/runner'
require 'omnipackage_agent/build/config'
require 'omnipackage_agent/extract_version'
require 'omnipackage_agent/distro'

module OmnipackageAgent
  module Build
    module_function

    def call(source_path, distros: nil, logger: ::OmnipackageAgent.logger, terminator: nil)
      build_config = ::OmnipackageAgent::Build::Config.new(source_path)

      job_variables = {
        version: ::OmnipackageAgent::ExtractVersion.new(build_config, source_path).call
      }

      build_config[:builds].select do |i|
        distro_id = i.fetch(:distro)
        ::OmnipackageAgent::Distro.new(distro_id).arch == ::OmnipackageAgent.arch && (distros.nil? || distros.include?(distro_id))
      end.map do |distro_build_config| # rubocop: disable Style/MultilineBlockChain
        ::OmnipackageAgent::Build::Runner.new(distro_build_config, logger: logger, terminator: terminator).run(source_path, job_variables)
      end.compact
    end
  end
end
