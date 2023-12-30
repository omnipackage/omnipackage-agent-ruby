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
require 'omnipackage_agent/container_runtime'

module OmnipackageAgent
  class Build
    class Runner
      attr_reader :build_conf, :distro, :image_cache, :config

      def initialize(build_conf:, config:, logger:, terminator: nil) # rubocop: disable Metrics/MethodLength
        @build_conf = build_conf
        @distro = ::OmnipackageAgent::Distro.new(build_conf.fetch(:distro))
        @log_string = ::StringIO.new
        @logger = logger.add_outputs(@log_string)
        @terminator = terminator
        @config = config
        @container_runtime = ::OmnipackageAgent::ContainerRuntime.new(logger: logger, config: config, terminator: terminator)
        @image_cache = ::OmnipackageAgent::ImageCache.new(
          container_runtime:  container_runtime,
          default_image:      build_conf[:image] || distro.image,
          distro_name:        distro.name,
          build_deps:         build_conf.fetch(:build_dependencies)
        )
      end

      def run(source_path, job_variables) # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
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
        ::OmnipackageAgent::Build::Output.new(
          success: success,
          artefacts: package.artefacts.map { |i| ::Pathname.new(i) },
          build_log: @logfile.path,
          build_config: build_conf
        )
      ensure
        @logfile&.write(@log_string.string)
        @logfile&.close
        @log_string.rewind
        @log_string.truncate(0)
      end

      private

      attr_reader :logger, :terminator, :container_runtime

      def build_cli(mounts, commands)
        mount_cli = mounts.map do |from, to|
          "--mount type=bind,source=#{from},target=#{to}"
        end.join(' ')

        <<~CLI
          #{image_cache.rm_cli} ; #{container_runtime.executable} run --name #{image_cache.container_name} --entrypoint /bin/sh #{mount_cli} #{image_cache.image} -c "#{commands.join(' && ')}" && #{image_cache.commit_cli}
        CLI
      end

      def execute(cli)
        container_runtime.execute(cli, lock_key: image_cache.container_name) do |output_line|
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
        end.new(source_path, job_variables, build_conf, distro, config: config)
      end
    end
  end
end
