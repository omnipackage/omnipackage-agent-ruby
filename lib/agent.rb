# frozen_string_literal: true

require_relative 'agent/version'
require_relative 'agent/rpm/specfile'
require_relative 'agent/build'
require_relative 'agent/subprocess'
require_relative 'agent/build_config'

require 'logger'
require 'pathname'
require 'yaml'

module Agent
  extend self

  attr_writer :logger

  def run(options = {})
    logger.info(RUBY_DESCRIPTION)

    if options[:headless]
      logger.info('running in headless mode')

      source_path = options[:source]
      build_config = Agent::BuildConfig.load_file(Pathname.new(source_path).join('.package-ipsum', 'config.yml'))

      build_config.distros.each do |distro_build_config|
        Agent::Build.new(distro_build_config).run(source_path)
      end

    end
  rescue StandardError => e
    logger.fatal(e)
    raise
  end

  def logger
    @logger ||= Logger.new($stdout)
  end
end
