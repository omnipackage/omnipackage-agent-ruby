# frozen_string_literal: true

require 'yaml'

module Agent
  module Yaml
    module_function

    def load_file(fpath, symbolize_names: false)
      if ::Gem::Version.new(::Psych::VERSION) > ::Gem::Version.new('4.0')
        ::YAML.load_file(fpath, symbolize_names: symbolize_names, aliases: true)
      else
        ::YAML.load_file(fpath, symbolize_names: symbolize_names)
      end
    end
  end
end
