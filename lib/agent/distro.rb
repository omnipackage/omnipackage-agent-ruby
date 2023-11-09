# frozen_string_literal: true

require 'yaml'

module Agent
  class Distro
    class << self
      def set_distro_configs!(hash)
        @@configs = hash.freeze
      end
    end

    attr_reader :name

    def initialize(distro)
      @name = distro
      @config = @@configs.fetch(distro)
    end

    def setup(build_dependencies)
      config.fetch('setup').map do |command|
        format(command, build_dependencies: build_dependencies.join(' '))
      end
    end

    def image
      config.fetch('image')
    end

    def rpm?
      config.fetch('package_type') == 'rpm'
    end

    def deb?
      config.fetch('package_type') == 'deb'
    end

    private

    attr_reader :config

    @@configs = ::YAML.load_file(::Pathname.new(__dir__).join('distros.yml'), aliases: true)
  end
end
