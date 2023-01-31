# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'logger'
require 'stringio'

require 'agent/utils/subprocess'
require 'agent/distro'
require 'agent/image_cache'
require 'agent/utils/path'
require 'agent/build/logfile'
require 'agent/build/output'
require 'agent/logging/multioutput'
require 'agent/build/rpm'
require 'agent/build/deb'

module Agent
  class Build
    attr_reader :build_conf, :distro, :image_cache

    def initialize(build_conf)
      @build_conf = build_conf
      @distro = ::Agent::Distro.new(build_conf.fetch(:distro))
      @log_string = ::StringIO.new
      @logger = ::Logger.new(::Agent::Logging::Multioutput.new($stdout, @log_string), formatter: ::Agent::Logging::Formatter.new)
      @image_cache = ::Agent::ImageCache.new(logger: logger)
    end

    def run(source_path, job_variables)
      logger.info("starting build for #{distro.name} in #{source_path}, variables: #{job_variables}")

      package = build_package(source_path, job_variables)
      @logfile = ::Agent::Build::Logfile.new(::Agent::Utils::Path.mkpath(package.output_path, 'build.log'))

      success = execute(build_cli(package.mounts, package.commands))
      if success
        image_cache.commit(container_name)
        logger.info("successfully finished build for #{distro.name}, artefacts: #{package.artefacts}, log: #{@logfile.path}")
      else
        logger.error("failed build for #{distro.name}")
      end
      ::Agent::Build::Output.new(success: success, artefacts: package.artefacts, build_log: @logfile.path)
    ensure
      image_cache.rm(container_name)
      @logfile&.write(@log_string.string)
      @logfile&.close
    end

    private

    attr_reader :logger

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
        #{::Agent.runtime} run --name #{container_name} --entrypoint /bin/sh #{mount_cli} #{image} -c "#{commands.join(' && ')}"
      CLI
    end

    def execute(cli)
      ::Agent::Utils::Subprocess.new(logger: logger).execute(cli) do |output_line|
        logger.info('container') { output_line }
      end&.success?
    end

    def build_package(source_path, job_variables)
      if distro.rpm?
        ::Agent::Build::Rpm
      elsif distro.deb?
        ::Agent::Build::Deb
      else
        raise "distro #{distro} not supported"
      end.new(source_path, job_variables, build_conf, distro)
    end
  end
end
