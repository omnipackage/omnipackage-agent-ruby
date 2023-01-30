# frozen_string_literal: true

require 'yaml'
require 'pathname'

module Agent
  module BuildConfig
    extend self

    def new(source_path)
      YAML.load_file(Pathname.new(source_path).join('.package-ipsum', 'config.yml'), symbolize_names: true)
    end
  end
end
