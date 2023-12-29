# frozen_string_literal: true

module OmnipackageAgent
  module Build
    class Output
      attr_reader :success, :artefacts, :build_log, :build_config

      def initialize(success:, artefacts:, build_log:, build_config:)
        @success = success
        @artefacts = artefacts
        @build_log = build_log
        @build_config = build_config
      end

      def distro
        ::OmnipackageAgent::Distro.new(build_config.fetch(:distro))
      end
    end
  end
end
