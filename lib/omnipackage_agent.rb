# frozen_string_literal: true

$LOAD_PATH.unshift ::File.expand_path('../vendor/liquid-5.4.0/lib', __dir__)

require 'logger'
require 'tmpdir'

require 'omnipackage_agent/version'
require 'omnipackage_agent/arch'
require 'omnipackage_agent/config'
require 'omnipackage_agent/build'
require 'omnipackage_agent/logging/logger'
require 'omnipackage_agent/api/connector'

module OmnipackageAgent
  module_function

  def headless(config, source)
    logger = ::OmnipackageAgent::Logging::Logger.new

    logger.info(::RUBY_DESCRIPTION)
    logger.info('running in headless mode')

    ::OmnipackageAgent::Build.new(logger: logger, config: config).call(source)
  end

  def api(config)
    logger = ::OmnipackageAgent::Logging::Logger.new

    logger.info(::RUBY_DESCRIPTION)
    logger.info("running with #{config.apihost} mothership")

    ::OmnipackageAgent::Api::Connector.new(config: config, logger: logger).join
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
end
