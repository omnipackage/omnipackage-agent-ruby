# frozen_string_literal: true

require 'erb'
require 'tmpdir'

require 'omnipackage_agent/utils/yaml'

module OmnipackageAgent
  class Config
    DEFAULT_LOCATION = ::File.expand_path('../../support/config.yml.example', __dir__)

    class << self
      def get(fpath = nil, overrides: {})
        h = load_file(DEFAULT_LOCATION)
        h.merge!(load_file(fpath))
        h.merge!(overrides)
        new(h)
      end

      private

      def load_file(fpath)
        if fpath
          content = ::File.read(fpath)
          yaml = ::ERB.new(content).result
          ::OmnipackageAgent::Yaml.load(yaml, symbolize_names: true)
        end || {}
      end
    end

    ATTRIBUTES = {
      container_runtime: ::String,
      apikey: ::String,
      apihost: ::String,
      build_dir: ::String,
      lockfiles_dir: ::String,
      image_cache_enable: [::TrueClass, ::FalseClass]
    }.freeze

    def initialize(hash, attributes = ATTRIBUTES) # rubocop: disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity
      attributes.each do |a, type|
        value = hash[a]
        if type.is_a?(::Hash)
          instance_variable_set("@#{a}", self.class.new(value, type))
        else
          if type.is_a?(::Array)
            raise ::TypeError, "attribute #{a}: #{value} must be one of #{type}, not #{value.class}" if type.none? { |t| value.is_a?(t) }
          else
            raise ::TypeError, "attribute #{a}: #{value} must be #{type}, not #{value.class}" unless value.is_a?(type)
          end

          instance_variable_set("@#{a}", value)
        end
        self.class.attr_reader(a)
      end
      freeze
    end
  end
end
