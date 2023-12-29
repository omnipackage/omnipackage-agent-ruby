# frozen_string_literal: true

require 'omnipackage_agent/utils/yaml'

module OmnipackageAgent
  class Distro
    class << self
      def set_distro_configs!(hash)
        @@configs = hash.fetch('distros').each_with_object({}) { |elem, acc| acc[elem['id']] = elem }.freeze
      end
    end

    attr_reader :name

    def initialize(distro)
      @name = distro
      @config = @@configs[distro] || (raise "no '#{distro}' in #{@@configs}")
    end

    def setup(build_dependencies)
      config.fetch('setup').map do |command|
        format(command, build_dependencies: build_dependencies.join(' '))
      end
    end

    def image
      config.fetch('image')
    end

    def arch
      config.fetch('arch')
    end

    def rpm?
      config.fetch('package_type') == 'rpm'
    end

    def deb?
      config.fetch('package_type') == 'deb'
    end

    private

    attr_reader :config

    set_distro_configs!(::OmnipackageAgent::Yaml.load_file(::Pathname.new(__dir__).join('distros.yml')))
  end
end
