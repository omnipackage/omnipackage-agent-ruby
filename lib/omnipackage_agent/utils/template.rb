# frozen_string_literal: true

require 'liquid'

module OmnipackageAgent
  module Utils
    class Template
      class << self
        def file_extension
          '.liquid'
        end
      end

      attr_reader :template

      def initialize(template_file_path)
        @template = ::File.read(template_file_path)
      end

      def render(params_hash)
        ::Liquid::Template.parse(template).render(params_hash.transform_keys(&:to_s))
      end

      def save(path, params_hash)
        ::File.write(path, render(params_hash))
        path
      end
    end
  end
end
