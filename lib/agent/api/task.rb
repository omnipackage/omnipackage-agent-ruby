# frozen_string_literal: true

require 'uri'

require 'agent/utils/download'
require 'agent/utils/path'

module Agent
  module Api
    class Task
      class << self
        def from_hash(task_payload)
          new(
            id:           task_payload.fetch('id'),
            tarball_url:  task_payload.fetch('sources_tarball_url')
          )
        end
      end

      attr_reader :id, :tarball_url

      def initialize(id:, tarball_url:)
        @id = id
        @tarball_url = tarball_url
      end

      def start(apikey, &block)
        @thread = ::Thread.new do
          sources_dir = ::Agent::Utils::Path.mkpath(::Agent.build_dir, "sources_#{id}").to_s

          ::Agent::Utils::Download.download_decompress(::URI.parse(tarball_url), sources_dir, headers: { 'X-APIKEY' => apikey })

          block.call(123)
        end

      end

      def to_hash
        {
          id:           id,
          tarball_url:  tarball_url,
          status:       thread&.status
        }.freeze
      end

      private

      attr_reader :thread
    end
  end
end
