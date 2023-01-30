# frozen_string_literal: true

require 'erb'

module Agent
  module Utils
    class Template
      class Renderer
        def initialize(hash)
          @h = hash.transform_keys(&:to_s)
        end

        def render(erb_template)
          ERB.new(erb_template).result(binding)
        end

        def build_time_rfc2822
          @build_time_rfc2822 ||= Time.now.utc.rfc2822
        end

        def method_missing(method_name, *arguments, &block)
          if h.key?(method_name.to_s)
            h.fetch(method_name.to_s)
          else
            super
          end
        end

        def respond_to_missing?(method_name, include_private = false)
          h.key?(method_name.to_s) || super
        end

        private

        attr_reader :h
      end

      attr_reader :template

      def initialize(template_file_path)
        @template = File.read(template_file_path)
      end

      def render(params_hash)
        Renderer.new(params_hash).render(template)
      end

      def save(path, params_hash)
        File.write(path, render(params_hash))
        path
      end
    end
  end
end
