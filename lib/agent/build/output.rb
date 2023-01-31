# frozen_string_literal: true

module Agent
  module Build
    class Output
      attr_reader :success, :artefacts, :build_log

      def initialize(success:, artefacts:, build_log:)
        @success = success
        @artefacts = artefacts
        @build_log = build_log
      end
    end
  end
end
