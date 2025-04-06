# frozen_string_literal: true

require 'omnipackage_agent/utils/yaml'
require 'omnipackage_agent/utils/path'

module OmnipackageAgent
  class Build
    module Config
      extend self

      def new(source_path, build_config_path: nil)
        build_config_path ||= '.omnipackage/config.yml'
        fpath = ::OmnipackageAgent::Utils::Path.mkpath(source_path, build_config_path)
        ::OmnipackageAgent::Yaml.load_file(fpath, symbolize_names: true)
      end
    end
  end
end
