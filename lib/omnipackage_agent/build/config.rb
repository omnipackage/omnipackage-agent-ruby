# frozen_string_literal: true

require 'omnipackage_agent/utils/yaml'
require 'omnipackage_agent/utils/path'

module OmnipackageAgent
  module Build
    module Config
      extend self

      def new(source_path)
        fpath = ::OmnipackageAgent::Utils::Path.mkpath(source_path, '.omnipackage', 'config.yml')
        ::OmnipackageAgent::Yaml.load_file(fpath, symbolize_names: true)
      end
    end
  end
end
