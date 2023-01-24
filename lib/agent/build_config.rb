# frozen_string_literal: true

require 'yaml'

module Agent
  class BuildConfig
    class << self
      def load_file(file_path)
        new(YAML.load_file(file_path))
      end
    end

    class ParseError < StandardError
    end

    class DistroBuildConfig
      attr_reader :distro, :build_dependencies, :image, :rpm, :deb

      def initialize(distro:, build_dependencies:, image:, rpm:, deb:)
        @distro = distro
        @build_dependencies = build_dependencies
        @image = image
        @rpm = rpm
        @deb = deb
        freeze
      end
    end

    class RpmConfig
      attr_reader :spec_template

      def initialize(spec_template:)
        @spec_template = spec_template
        freeze
      end
    end

    attr_reader :distros

    def initialize(hash)
      @distros = hash.fetch('distros').map do |dc|
        if dc['rpm']
          rpm = RpmConfig.new(spec_template: dc.fetch('rpm').fetch('spec_template'))
        elsif dc['deb']
          deb = nil
        else
          raise ParseError, "#{dc} must specify rpm or deb package config"
        end

        DistroBuildConfig.new(
          distro:             dc.fetch('distro'),
          build_dependencies: dc.fetch('build_dependencies'),
          image:              dc['image'],
          rpm:                rpm,
          deb:                deb
        )
      end
      freeze
    end
  end
end
