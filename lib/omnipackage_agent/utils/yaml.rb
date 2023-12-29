# frozen_string_literal: true

require 'yaml'

module OmnipackageAgent
  module Yaml
    module_function

    def load_file(fpath, symbolize_names: false)
      if ::Gem::Version.new(::Psych::VERSION) > ::Gem::Version.new('4.0')
        ::YAML.load_file(fpath, symbolize_names: symbolize_names, aliases: true)
      else
        ::YAML.load_file(fpath, symbolize_names: symbolize_names)
      end
    end

    def load(string, symbolize_names: false)
      if ::Gem::Version.new(::Psych::VERSION) > ::Gem::Version.new('4.0')
        ::YAML.load(string, symbolize_names: symbolize_names, aliases: true) # rubocop: disable Security/YAMLLoad
      else
        ::YAML.load(string, symbolize_names: symbolize_names) # rubocop: disable Security/YAMLLoad
      end
    end
  end
end
