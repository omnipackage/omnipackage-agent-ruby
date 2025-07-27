# frozen_string_literal: true

require 'omnipackage_agent/utils/yaml'

module OmnipackageAgent
  class Distro
    class << self
      include ::Enumerable

      def set_distro_configs!(hash)
        @@configs = hash.fetch('distros').each_with_object({}) { |elem, acc| acc[elem['id']] = elem }.freeze
      end

      def exists?(distro)
        @@configs.key?(distro)
      end

      def each(&block)
        if block
          @@configs.each_key { |distro| block.call(new(distro)) }
        else
          ::Enumerator.new do |y|
            @@configs.each_key { |distro| y << new(distro) }
          end
        end
      end
    end

    attr_reader :name

    def initialize(distro)
      @name = distro
      @config = @@configs[distro] || (raise "no '#{distro}' in #{@@configs}")
    end

    def setup(build_dependencies)
      config.fetch('setup').map do |command|
        deps = build_dependencies.join(' ')
        command.gsub('%{build_dependencies}', deps)
        # format(command, build_dependencies: build_dependencies.join(' '))
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

    def to_s
      name
    end

    def humanized_name
      config.fetch('name')
    end

    def deprecated
      config.fetch('deprecated', nil)
    end

    private

    attr_reader :config

    set_distro_configs!(::OmnipackageAgent::Yaml.load_file(::Pathname.new(__dir__).join('../../support/distros.yml')))
  end
end
