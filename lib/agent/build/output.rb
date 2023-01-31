# frozen_string_literal: true

module Agent
  module Build
    class Output
      attr_reader :success, :artefacts, :build_log, :build_config

      def initialize(success:, artefacts:, build_log:, build_config:)
        @success = success
        @artefacts = artefacts
        @build_log = build_log
        @build_config = build_config
      end
    end
  end
end
