# frozen_string_literal: true

require 'logger'
require 'tmpdir'

require 'agent/version'
require 'agent/rpm/specfile'
require 'agent/build'
require 'agent/build_config'
require 'agent/logging/formatter'
require 'agent/extract_version'

module Agent
  extend self

  def run(options = {})
    logger.info(::RUBY_DESCRIPTION)

    if options[:headless]
      logger.info('running in headless mode')

      source_path = options[:source]
      build_config = ::Agent::BuildConfig.new(source_path)

      job_variables = {
        version: ::Agent::ExtractVersion.new(build_config, source_path).call
      }

      build_config[:builds].each do |distro_build_config|
        ::Agent::Build.new(distro_build_config).run(source_path, job_variables)
      end

    end
  rescue ::StandardError => e
    logger.fatal(e)
    raise
  end

  def logger
    @logger ||= ::Logger.new($stdout, formatter: ::Agent::Logging::Formatter.new)
  end

  def build_dir
    @build_dir ||= "#{::Dir.tmpdir}/build-package-ipsum"
  end

  def runtime
    @runtime ||= 'podman' # docker or podman
  end
end
