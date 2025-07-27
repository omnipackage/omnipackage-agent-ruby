# frozen_string_literal: true

def __load_vendor_gem__(gem)
  $LOAD_PATH.unshift ::File.expand_path("../vendor/#{gem}/lib", __dir__)
end
__load_vendor_gem__('liquid-5.5.1-fork')
__load_vendor_gem__('logger-1.7.0') if ::Gem::Version.new(RUBY_VERSION) >= ::Gem::Version.new('3.4')

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
      raise "please install #{name}" unless system("#{cmd} > /dev/null 2>&1")
    end
  end
end
