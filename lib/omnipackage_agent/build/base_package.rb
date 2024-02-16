# frozen_string_literal: true

require 'omnipackage_agent/utils/path'

module OmnipackageAgent
  class Build
    class BasePackage
      attr_reader :source_path, :job_variables, :build_conf, :distro, :build_dir
      attr_reader :output_path, :commands, :mounts # set these in setup method

      def initialize(source_path, job_variables, build_conf, distro, build_dir)
        @source_path = source_path
        @job_variables = job_variables
        @distro = distro
        @build_conf = build_conf
        @build_dir = build_dir
        setup
      end

      def version
        job_variables.fetch(:version)
      end

      def build_deps
        build_conf.fetch(:build_dependencies)
      end

      def artefacts
      end

      def before_build_script(relative_to = source_path)
        bbs = build_conf[:before_build_script]
        return unless bbs

        if ::File.exist?(::OmnipackageAgent::Utils::Path.mkpath(source_path, bbs))
          ::OmnipackageAgent::Utils::Path.mkpath(relative_to, bbs).to_s
        else
          bbs
        end
      end

      private

      def setup
      end
    end
  end
end
