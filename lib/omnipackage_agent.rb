# frozen_string_literal: true

$LOAD_PATH.unshift ::File.expand_path('../vendor/liquid-5.4.0/lib', __dir__)

require 'omnipackage_agent/version'
require 'omnipackage_agent/arch'
require 'omnipackage_agent/config'
require 'omnipackage_agent/build'
require 'omnipackage_agent/logging/logger'
require 'omnipackage_agent/api/connector'

module OmnipackageAgent
  module_function

  def run(config, logger: ::OmnipackageAgent::Logging::Logger.new)
    logger.info("starting agent #{::OmnipackageAgent::VERSION} with #{config.apihost} mothership, #{ruby_env_info}")

    if config.apikey.empty?
      logger.fatal('you have to specify apikey in the config file')
      return
    end

    ::OmnipackageAgent::Api::Connector.new(config: config, logger: logger).join
  end

  def ruby_env_info
    "#{::RUBY_DESCRIPTION} (#{::RbConfig.ruby})"
  end

  def check_system_packages!
    ['tar', 'xz', 'flock'].each do |b| # rubocop: disable Style/WordArray
      name, cmd = if b.is_a?(::Hash)
                    [b.keys.first, b.values.first]
                  else
                    [b, "#{b} --version"]
                  end
      raise "please install #{name}" unless system("#{cmd} &> /dev/null")
    end
  end
end
