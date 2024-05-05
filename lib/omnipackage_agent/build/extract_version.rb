# frozen_string_literal: true

require 'omnipackage_agent/utils/path'

module OmnipackageAgent
  class Build
    class ExtractVersion
      attr_reader :config, :source_path

      def initialize(build_config, source_path)
        @config = build_config.fetch(:extract_version)
        @source_path = source_path
      end

      def call
        case config.fetch(:provider)
        when 'file'
          file
        when 'static'
          config.fetch(:static).fetch(:version)
        else
          raise "version provider '#{config.fetch(:provider)}' not supported"
        end
      end

      private

      def file
        regex = ::Regexp.new(config.fetch(:file).fetch(:regex))
        version_file = ::File.read(::OmnipackageAgent::Utils::Path.mkpath(source_path, config.fetch(:file).fetch(:file)))
        matchdata = regex.match(version_file) || (raise "no match #{regex} in #{config.fetch(:file).fetch(:file)}")
        matchdata[1]
      end
    end
  end
end
