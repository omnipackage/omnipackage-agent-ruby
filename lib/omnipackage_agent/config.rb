# frozen_string_literal: true

require 'erb'

require 'omnipackage_agent/utils/yaml'

module OmnipackageAgent
  class Config
    DEFAULT_LOCATION = ::File.expand_path('../../support/config.yml.example', __dir__)

    class << self
      def get(options = {})
        fpath = options.delete(:config) || DEFAULT_LOCATION
        content = ::File.read(fpath)
        yaml = ::ERB.new(content).result
        new(::OmnipackageAgent::Yaml.load(yaml, symbolize_names: true).merge(options))
      end
    end

    ATTRIBUTES = {
      container_runtime: ::String,
      apikey: ::String,
      apihost: ::String,
      build_dir: ::String,
      lockfiles_dir: ::String
    }.freeze

    def initialize(hash, attributes = ATTRIBUTES) # rubocop: disable Metrics/MethodLength
      attributes.each do |a, type|
        value = hash.fetch(a)
        if type.is_a?(::Hash)
          instance_variable_set("@#{a}", self.class.new(value, type))
        else
          raise ::TypeError, "attribute #{a}: #{value} must be #{type}, not #{value.class}" unless value.is_a?(type)

          instance_variable_set("@#{a}", value)
        end
        self.class.attr_reader(a)
      end
      freeze
    end
  end
end
