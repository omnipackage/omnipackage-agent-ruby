# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'stringio'

require 'omnipackage_agent/logging/multioutput'
require 'omnipackage_agent/utils/subprocess'
require 'omnipackage_agent/utils/path'
require 'omnipackage_agent/distro'
require 'omnipackage_agent/build/image_cache'
require 'omnipackage_agent/build/logfile'
require 'omnipackage_agent/build/output'
require 'omnipackage_agent/build/rpm/package'
require 'omnipackage_agent/build/deb/package'
require 'omnipackage_agent/build/lock'

module OmnipackageAgent
  class Build
    class Runner
      def initialize(build_conf:, source_path:, job_variables:, config:, logger:, terminator:) # rubocop: disable Metrics/ParameterLists
        @config = config
        @log_string = ::StringIO.new
        @logger = logger.add_outputs(log_string)
        @subprocess = ::OmnipackageAgent::Utils::Subprocess.new(logger: logger, terminator: terminator)

        distro = ::OmnipackageAgent::Distro.new(build_conf.fetch(:distro))
        @package = build_package(source_path, job_variables, distro, build_conf)
        @image_cache = build_image_cache(distro, build_conf)
      end

      def call
        log_start

        logfile = create_build_log

        result = build(logfile)
        log_finish(result)

        result
      ensure
        logfile.write(log_string.string)
        logfile.close
      end

      private

      attr_reader :logger, :log_string, :subprocess, :config, :package, :image_cache

      def log_start
        logger.info("starting build for #{package.distro} at #{package.source_path}, variables: #{package.job_variables}")
      end

      def log_finish(result)
        if result.success
          logger.info("successfully finished build for #{package.distro} in #{result.total_time}s, artefacts: #{result.artefacts.map(&:to_s)}, log: #{result.build_log}")
        else
          logger.error("failed build for #{package.distro} in #{result.total_time}s, log: #{result.build_log}")
        end
      end

      def build(logfile) # rubocop: disable Metrics/AbcSize
        start_time = current_monotonic_time
        success = execute(build_cli(package.mounts, package.commands))

        ::OmnipackageAgent::Build::Output.new(
          success:      success,
          artefacts:    package.artefacts.map { |i| ::Pathname.new(i) },
          build_log:    logfile.path,
          build_config: package.build_conf,
          total_time:   (current_monotonic_time - start_time).round
        )
      end

      def build_cli(mounts, commands)
        mount_cli = mounts.map do |from, to|
          "--mount type=bind,source=#{from},target=#{to}"
        end.join(' ')

        <<~CLI
          #{lock.to_cli} '#{image_cache.rm_cli} ; #{config.container_runtime} run --name #{image_cache.container_name} --entrypoint /bin/sh #{mount_cli} #{image_cache.image} -c "#{commands.join(' && ')}" && #{image_cache.commit_cli}'
        CLI
      end

      def execute(cli)
        subprocess.execute(cli) do |output_line|
          logger.info('container') { output_line }
        end&.success? || false # nil can be in case of termination
      end

      def build_package(source_path, job_variables, distro, build_conf)
        if distro.rpm?
          ::OmnipackageAgent::Build::Rpm::Package
        elsif distro.deb?
          ::OmnipackageAgent::Build::Deb::Package
        else
          raise "distro #{distro} not supported"
        end.new(source_path, job_variables, build_conf, distro, config: config)
      end

      def current_monotonic_time
        ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
      end

      def create_build_log
        ::OmnipackageAgent::Build::Logfile.new(::OmnipackageAgent::Utils::Path.mkpath(package.output_path, 'build.log'))
      end

      def lock
        @lock ||= ::OmnipackageAgent::Build::Lock.new(config: config, key: image_cache.container_name)
      end

      def build_image_cache(distro, build_conf)
        ::OmnipackageAgent::Build::ImageCache.new(
          subprocess:     subprocess,
          config:         config,
          default_image:  build_conf.fetch(:image, distro.image),
          distro_name:    distro.name,
          build_deps:     build_conf.fetch(:build_dependencies)
        )
      end
    end
  end
end
