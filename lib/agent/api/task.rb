# frozen_string_literal: true

require 'uri'

require 'agent/utils/path'
require 'agent/build'

module Agent
  module Api
    class Task
      attr_reader :id, :tarball_url, :upload_url, :downloader, :build_outputs, :exception, :logger

      def initialize(id:, tarball_url:, upload_url:, downloader:, logger:)
        @id = id
        @tarball_url = tarball_url
        @upload_url = upload_url
        @downloader = downloader
        @logger = logger
      end

      def start(&block) # rubocop: disable Metrics/MethodLength
        sources_dir = ::Agent::Utils::Path.mkpath(::Agent.build_dir, "sources_#{id}").to_s
        ::FileUtils.mkdir_p(sources_dir)

        @thread = ::Thread.new do
          download_tarball(sources_dir)
          @build_outputs = ::Agent::Build.call(sources_dir)
          upload_artefacts
        rescue ::StandardError => e
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
          upload_url:   upload_url,
          status:       thread&.status
        }.freeze
      end

      private

      attr_reader :thread

      def download_tarball(sources_dir)
        logger.info("downloading sources from #{tarball_url} to #{sources_dir}")
        downloader.download_decompress(tarball_url, sources_dir)
      end

      def upload_artefacts
        build_outputs.each do |i|
          next unless i.success
          i.artefacts.each do |art|
            logger.info("uploading artefact #{art}")
            downloader.upload(upload_url, art)
          end
          logger.info("uploading build log #{i.build_log}")
          downloader.upload(upload_url, i.build_log)
        end
      end
    end
  end
end
