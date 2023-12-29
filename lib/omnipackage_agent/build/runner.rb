# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'stringio'

require 'omnipackage_agent/logging/multioutput'
require 'omnipackage_agent/utils/subprocess'
require 'omnipackage_agent/utils/path'
require 'omnipackage_agent/distro'
require 'omnipackage_agent/image_cache'
require 'omnipackage_agent/build/logfile'
require 'omnipackage_agent/build/output'
require 'omnipackage_agent/build/rpm/package'
require 'omnipackage_agent/build/deb/package'

module OmnipackageAgent
  module Build
    class Runner
      attr_reader :build_conf, :distro, :image_cache

      def initialize(build_conf, logger:, terminator: nil)
        @build_conf = build_conf
        @distro = ::OmnipackageAgent::Distro.new(build_conf.fetch(:distro))
        @log_string = ::StringIO.new
        @logger = logger.add_outputs(@log_string)
        @terminator = terminator
        @image_cache = ::OmnipackageAgent::ImageCache.new(logger: logger)
      end

      def run(source_path, job_variables) # rubocop: disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        return if terminator&.called?

        logger.info("starting build for #{distro.name} in #{source_path}, variables: #{job_variables}")

        package = build_package(source_path, job_variables)
        @logfile = ::OmnipackageAgent::Build::Logfile.new(::OmnipackageAgent::Utils::Path.mkpath(package.output_path, 'build.log'))

        success = execute(build_cli(package.mounts, package.commands))
        if success
          logger.info("successfully finished build for #{distro.name}, artefacts: #{package.artefacts}, log: #{@logfile.path}")
        else
          logger.error("failed build for #{distro.name}")
        end
        image_cache.commit(container_name) unless terminator&.called?
        ::OmnipackageAgent::Build::Output.new(
          success: success,
          artefacts: package.artefacts.map { |i| ::Pathname.new(i) },
          build_log: @logfile.path,
          build_config: build_conf
        )
      ensure
        image_cache.rm(container_name)
        @logfile&.write(@log_string.string)
        @logfile&.close
        @log_string.rewind
        @log_string.truncate(0)
      end

      private

      attr_reader :logger, :terminator

      def build_deps
        build_conf.fetch(:build_dependencies)
      end

      def container_name
        @container_name ||= image_cache.generate_container_name(distro.name, build_deps)
      end

      def image
        @image ||= image_cache.image(container_name, build_conf[:image] || distro.image)
      end

      def build_cli(mounts, commands)
        mount_cli = mounts.map do |from, to|
          "--mount type=bind,source=#{from},target=#{to}"
        end.join(' ')

        <<~CLI
          #{::OmnipackageAgent.config.container_runtime} run --name #{container_name} --entrypoint /bin/sh #{mount_cli} #{image} -c "#{commands.join(' && ')}"
        CLI
      end

      def execute(cli)
        ::OmnipackageAgent::Utils::Subprocess.new(logger: logger, terminator: terminator).execute(cli) do |output_line|
          logger.info('container') { output_line }
        end&.success?
      end

      def build_package(source_path, job_variables)
        if distro.rpm?
          ::OmnipackageAgent::Build::Rpm::Package
        elsif distro.deb?
          ::OmnipackageAgent::Build::Deb::Package
        else
          raise "distro #{distro} not supported"
        end.new(source_path, job_variables, build_conf, distro)
      end
    end
  end
end
