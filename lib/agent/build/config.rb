# frozen_string_literal: true

require 'yaml'

require 'agent/utils/path'

module Agent
  module Build
    module Config
      extend self

      def new(source_path)
        fpath = ::Agent::Utils::Path.mkpath(source_path, '.omnipackage', 'config.yml')
        ::YAML.load_file(fpath, symbolize_names: true)
      end
    end
  end
end
