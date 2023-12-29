# frozen_string_literal: true

require 'erb'

require 'agent/utils/yaml'

module Agent
  class Config
    class << self
      def load!(path, merge_with = {})
        content = ::File.read(path)
        yaml = ::ERB.new(content).result
        new(::Agent::Yaml.load(yaml, symbolize_names: true).merge(merge_with))
      end
    end

    ATTRIBUTES = {
      container_runtime: ::String,
      apikey: ::String,
      apihost: ::String
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
