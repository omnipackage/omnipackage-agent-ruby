# frozen_string_literal: true

require 'erb'
require 'tmpdir'

require 'omnipackage_agent/utils/yaml'

module OmnipackageAgent
  class Config
    class << self
      def get(options = {})
        fpath = options.delete(:config)
        hash = if fpath
                 yaml = ::ERB.new(::File.read(fpath)).result
                 ::OmnipackageAgent::Yaml.load(yaml, symbolize_names: true)
               end || {}
        hash.merge!(options)
        new(hash)
      end
    end

    ATTRIBUTES = {
      container_runtime:  { type: ::String, default: -> { ::OmnipackageAgent.detect_container_runtime } },
      apikey:             { type: ::String, default: '' },
      apihost:            { type: ::String, default: 'https://omnipackage.org' },
      build_dir:          { type: ::String, default: "#{::Dir.tmpdir}/omnipackage-build" },
      lockfiles_dir:      { type: ::String, default: "#{::Dir.tmpdir}/omnipackage-lock" }
    }.freeze

    def initialize(hash, attributes = ATTRIBUTES) # rubocop: disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      attributes.each do |a, meta|
        value = hash.is_a?(::Hash) ? hash[a] : nil
        if meta.key?(:type)
          if value.nil?
            raise ::TypeError, "attribute #{a} does not have default value and must exist" unless meta[:default]

            value = if meta[:default].is_a?(::Proc)
                      meta[:default].call
                    else
                      meta[:default]
                    end
          end

          raise ::TypeError, "attribute #{a}: #{value} must be #{meta[:type]}, not #{value.class}" unless value.is_a?(meta[:type])

          instance_variable_set("@#{a}", value)
        else # nested hash
          instance_variable_set("@#{a}", self.class.new(value, meta))
        end

        self.class.attr_reader(a)
      end
      freeze
    end
  end
end
