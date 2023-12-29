# frozen_string_literal: true

require 'uri'

require 'omnipackage_agent/utils/path'
require 'omnipackage_agent/build'
require 'omnipackage_agent/logging/stdout2'

module OmnipackageAgent
  module Api
    class Task
      attr_reader :id, :tarball_url, :upload_url, :distros, :downloader, :build_outputs, :exception, :logger, :config

      def initialize(id:, tarball_url:, upload_url:, distros:, downloader:, logger:, config:) # rubocop: disable Metrics/ParameterLists
        @id = id
        @distros = distros
        @tarball_url = tarball_url
        @upload_url = upload_url
        @downloader = downloader
        @config = config
        @stdout2 = ::OmnipackageAgent::Logging::Stdout2.new
        @logger = logger.add_outputs(stdout2)
        @terminator = ::OmnipackageAgent::Utils::Terminator.new
      end

      def start(&block) # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
        sources_dir = ::OmnipackageAgent::Utils::Path.mkpath(config.build_dir, "sources_#{id}").to_s
        ::FileUtils.mkdir_p(sources_dir)

        @thread = ::Thread.new do
          download_tarball(sources_dir)
          @build_outputs = ::OmnipackageAgent::Build.new(config: config, logger: logger).call(sources_dir, distros: distros, terminator: terminator)
          upload_artefacts
        rescue ::StandardError => e
          @exception = e
          logger.error("error: #{e}")
          logger.debug(e.backtrace.join("\n"))
        ensure
          ::FileUtils.rm_rf(sources_dir)
          block.call(self)
          freeze
        end
      end

      def stop
        terminator.call
      end

      def to_hash
        {
          id:           id,
          tarball_url:  tarball_url,
          upload_url:   upload_url,
          distros:      distros,
          status:       thread&.status
        }
      end

      def read_log
        stdout2.dequeue
      end

      private

      attr_reader :thread, :stdout2, :terminator

      def download_tarball(sources_dir)
        logger.info("downloading sources from #{tarball_url} to #{sources_dir}")
        downloader.download_decompress(tarball_url, sources_dir)
      end

      def upload_artefacts # rubocop: disable Metrics/AbcSize
        build_outputs.each do |i|
          if i.success
            i.artefacts.each do |art|
              logger.info("uploading artefact #{art}")
              upload(art, i.distro.name, i.success)
            end
          end

          logger.info("uploading build log #{i.build_log}")
          upload(i.build_log, i.distro.name, i.success)
        end
      end

      def upload(file, distro, success)
        attempts ||= 30
        downloader.upload(upload_url, file, { 'distro' => distro, 'error' => (!success).to_s })
      rescue ::StandardError => e
        attempts -= 1
        if attempts > 0
          logger.debug("upload error: #{e}, retrying...")
          sleep(10)
          retry
        end
      end
    end
  end
end
