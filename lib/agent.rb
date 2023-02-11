# frozen_string_literal: true

$LOAD_PATH.unshift ::File.expand_path('../vendor/liquid-5.4.0/lib', __dir__)

require 'logger'
require 'tmpdir'

require 'agent/version'
require 'agent/build/runner'
require 'agent/build/config'
require 'agent/logging/formatter'
require 'agent/extract_version'

module Agent
  extend self

  def run(options = {})
    logger.info(::RUBY_DESCRIPTION)

    if options[:headless]
      logger.info('running in headless mode')
      build(options[:source])
    end
  rescue ::StandardError => e
    logger.fatal(e)
    raise
  end

  def build(source_path)
    build_config = ::Agent::Build::Config.new(source_path)

    job_variables = {
      version: ::Agent::ExtractVersion.new(build_config, source_path).call
    }

    build_config[:builds].map do |distro_build_config|
      ::Agent::Build::Runner.new(distro_build_config).run(source_path, job_variables)
    end
  end

  def logger
    @logger ||= ::Logger.new($stdout, formatter: ::Agent::Logging::Formatter.new)
  end

  def build_dir
    @build_dir ||= "#{::Dir.tmpdir}/build-omnipackage"
  end

  def runtime
    @runtime ||= 'podman' # docker or podman
  end
end
