# frozen_string_literal: true

$LOAD_PATH.unshift ::File.expand_path('../vendor/liquid-5.4.0/lib', __dir__)

require 'logger'
require 'tmpdir'

require 'omnipackage_agent/version'
require 'omnipackage_agent/config'
require 'omnipackage_agent/build'
require 'omnipackage_agent/logging/logger'
require 'omnipackage_agent/api/connector'

module OmnipackageAgent
  extend self

  attr_writer :config

  def run(options = {}) # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
    logger = ::OmnipackageAgent::Logging::Logger.new

    logger.info(::RUBY_DESCRIPTION)
    check_system_packages!

    if options[:headless]
      logger.info('running in headless mode')
      ::OmnipackageAgent::Build.call(options[:source], logger: logger)
    else
      logger.info("running with #{config.apihost} mothership")
      ::OmnipackageAgent::Api::Connector.new(config.apihost, config.apikey, logger: logger).join
    end
  rescue ::StandardError => e
    logger.fatal(e)
    raise
  end

  def check_system_packages!
    ['tar', 'xz'].each do |b| # rubocop: disable Style/WordArray
      name, cmd = if b.is_a?(::Hash)
                    [b.keys.first, b.values.first]
                  else
                    [b, "#{b} --version"]
                  end
      raise "please install #{name}" unless system("#{cmd} &> /dev/null")
    end
  end

  def config
    @config ||= ::OmnipackageAgent::Config.load!(::File.expand_path('../support/config.yml.example', __dir__))
  end

  def arch
    @arch ||= `uname -m`.strip
  end
end
