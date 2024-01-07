# frozen_string_literal: true

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

      private

      def setup
      end
    end
  end
end
