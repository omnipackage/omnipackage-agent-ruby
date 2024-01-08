# frozen_string_literal: true

module OmnipackageAgent
  class Build
    class Output
      attr_reader :success, :artefacts, :build_log, :build_config, :total_time, :lockwait_time

      def initialize(success:, artefacts:, build_log:, build_config:, total_time:, lockwait_time:) # rubocop: disable Metrics/ParameterLists
        @success = success
        @artefacts = artefacts
        @build_log = build_log
        @build_config = build_config
        @total_time = total_time
        @lockwait_time = lockwait_time
      end

      def distro
        ::OmnipackageAgent::Distro.new(build_config.fetch(:distro))
      end
    end
  end
end
