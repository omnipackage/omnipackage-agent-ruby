# frozen_string_literal: true

$LOAD_PATH.unshift ::File.expand_path('../vendor/liquid-5.4.0/lib', __dir__)

require 'logger'
require 'tmpdir'

require 'agent/version'
require 'agent/config'
require 'agent/build'
require 'agent/logging/logger'
require 'agent/api/connector'

module Agent
  extend self

  attr_writer :config

  def run(options = {}) # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
    logger.info(::RUBY_DESCRIPTION)
    check_system_packages!

    if options[:headless]
      logger.info('running in headless mode')
      ::Agent::Build.call(options[:source])
    else
      logger.info("running with #{config.apihost} mothership")
      ::Agent::Api::Connector.new(config.apihost, config.apikey).join
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
    @config ||= ::Agent::Config.load!(::File.expand_path('../support/config.yml.example', __dir__))
  end

  def logger
    @logger ||= ::Agent::Logging::Logger.new
  end

  def build_dir
    @build_dir ||= "#{::Dir.tmpdir}/build-omnipackage"
  end

  def arch
    @arch ||= `uname -m`.strip
  end
end
