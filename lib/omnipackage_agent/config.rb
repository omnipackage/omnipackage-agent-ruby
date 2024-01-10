# frozen_string_literal: true

require 'erb'
require 'tmpdir'

require 'omnipackage_agent/utils/yaml'
require 'omnipackage_agent/utils/path'

module OmnipackageAgent
  class Config
    ATTRIBUTES = {
      container_runtime:  { type: ::String, default: -> { ::OmnipackageAgent.detect_container_runtime } }.freeze,
      apikey:             { type: ::String, default: '' }.freeze,
      apihost:            { type: ::String, default: 'https://omnipackage.org' }.freeze,
      build_dir:          { type: ::String, default: ::OmnipackageAgent::Utils::Path.mkpath(::Dir.tmpdir, 'omnipackage-build').to_s }.freeze,
      lockfiles_dir:      { type: ::String, default: ::OmnipackageAgent::Utils::Path.mkpath(::Dir.tmpdir, 'omnipackage-lock').to_s }.freeze
    }.freeze

    class << self
      def get(fpath = nil)
        hash = if fpath
                 yaml = ::ERB.new(::File.read(fpath)).result
                 ::OmnipackageAgent::Yaml.load(yaml, symbolize_names: true)
               end || {}
        new(hash)
      end
    end

    def initialize(hash, attributes = ATTRIBUTES) # rubocop: disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      attributes.each do |a, meta|
        value = hash.is_a?(::Hash) ? hash[a] : nil

        if meta.key?(:type)
          if value.nil?
            if !meta.key?(:default)
              raise ::TypeError, "attribute #{a} does not have default value and must exist"
            elsif meta[:default].is_a?(::Proc)
              value = meta[:default].call
            else
              value = meta[:default]
            end
          end

          raise ::TypeError, "attribute #{a}: #{value} must be #{meta[:type]}, not #{value.class}" unless value.is_a?(meta[:type])
        else
          value = self.class.new(value, meta)
        end

        instance_variable_set("@#{a}", value)
        self.class.attr_reader(a)
      end
      freeze
    end
  end
end
