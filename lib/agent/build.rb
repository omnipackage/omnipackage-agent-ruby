# frozen_string_literal: true

require 'agent/build/runner'
require 'agent/build/config'
require 'agent/extract_version'
require 'agent/distro'

module Agent
  module Build
    module_function

    def call(source_path, distros: nil, logger: ::Agent.logger)
      build_config = ::Agent::Build::Config.new(source_path)

      job_variables = {
        version: ::Agent::ExtractVersion.new(build_config, source_path).call
      }

      build_config[:builds].select do |i|
        distro_id = i.fetch(:distro)
        ::Agent::Distro.new(distro_id).arch == ::Agent.arch && (distros.nil? || distros.include?(distro_id))
      end.map do |distro_build_config| # rubocop: disable Style/MultilineBlockChain
        ::Agent::Build::Runner.new(distro_build_config, logger: logger).run(source_path, job_variables)
      end
    end
  end
end
