# frozen_string_literal: true

require 'agent/build/runner'
require 'agent/build/config'
require 'agent/extract_version'

module Agent
  module Build
    module_function

    def call(source_path)
      build_config = ::Agent::Build::Config.new(source_path)

      job_variables = {
        version: ::Agent::ExtractVersion.new(build_config, source_path).call
      }

      build_config[:builds].map do |distro_build_config|
        ::Agent::Build::Runner.new(distro_build_config).run(source_path, job_variables)
      end
    end
  end
end
