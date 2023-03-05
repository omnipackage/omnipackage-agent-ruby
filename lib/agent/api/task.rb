# frozen_string_literal: true

require 'uri'

require 'agent/utils/path'
require 'agent/build'

module Agent
  module Api
    class Task
      attr_reader :id, :tarball_url, :downloader, :build_outputs, :exception

      def initialize(id:, tarball_url:, downloader:)
        @id = id
        @tarball_url = tarball_url
        @downloader = downloader
      end

      def start(&block) # rubocop: disable Metrics/MethodLength
        sources_dir = ::Agent::Utils::Path.mkpath(::Agent.build_dir, "sources_#{id}").to_s
        ::FileUtils.mkdir_p(sources_dir)

        @thread = ::Thread.new do
          downloader.download_decompress(tarball_url, sources_dir)
          @build_outputs = ::Agent::Build.call(sources_dir)
        rescue ::StandarError => e
          @exception = e
        ensure
          ::FileUtils.rm_rf(sources_dir)
          block.call(self)
          freeze
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
