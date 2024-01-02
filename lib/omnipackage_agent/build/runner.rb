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
      attr_reader :subprocess, :build_conf, :distro, :image_cache, :config

      def initialize(build_conf:, config:, logger:, terminator: nil) # rubocop: disable Metrics/MethodLength
        @build_conf = build_conf
        @distro = ::OmnipackageAgent::Distro.new(build_conf.fetch(:distro))
        @log_string = ::StringIO.new
        @logger = logger.add_outputs(@log_string)
        @config = config
        @subprocess = ::OmnipackageAgent::Utils::Subprocess.new(logger: logger, terminator: terminator)

        @image_cache = ::OmnipackageAgent::Build::ImageCache.new(
          subprocess:     subprocess,
          config:         config,
          default_image:  build_conf[:image] || distro.image,
          distro_name:    distro.name,
          build_deps:     build_conf.fetch(:build_dependencies)
        )
      end

      def call(source_path, job_variables) # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
        logger.info("starting build for #{distro.name} in #{source_path}, variables: #{job_variables}")

        package = build_package(source_path, job_variables)
        @logfile = ::OmnipackageAgent::Build::Logfile.new(::OmnipackageAgent::Utils::Path.mkpath(package.output_path, 'build.log'))

        lock = ::OmnipackageAgent::Build::Lock.new(config: config, key: image_cache.container_name)

        start_time = current_monotonic_time
        success = execute(build_cli(package.mounts, package.commands, lock))
        total_duration = (current_monotonic_time - start_time).round
        if success
          logger.info("successfully finished build for #{distro.name} in #{total_duration} secs, artefacts: #{package.artefacts}, log: #{@logfile.path}")
        else
          logger.error("failed build for #{distro.name} in #{total_duration} secs")
        end
        ::OmnipackageAgent::Build::Output.new(
          success:      success,
          artefacts:    package.artefacts.map { |i| ::Pathname.new(i) },
          build_log:    @logfile.path,
          build_config: build_conf
        )
      ensure
        @logfile&.write(@log_string.string)
        @logfile&.close
        @log_string.rewind
        @log_string.truncate(0)
      end

      private

      attr_reader :logger

      def build_cli(mounts, commands, lock)
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

      def current_monotonic_time
        ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
      end
    end
  end
end
