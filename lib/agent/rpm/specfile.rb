# frozen_string_literal: true

require_relative '../utils/template'

module Agent
  module Rpm
    class Specfile
      attr_reader :template

      def initialize(template_file_path)
        @template = File.read(template_file_path)
      end

      def name
        /[Nn]ame:(.+)/.match(template)[1].strip
      end

      def render(params_hash)
        Agent::Utils::Template.new(params_hash).render(template)
      end

      def save(path, params_hash)
        File.write(path, render(params_hash))
        path
      end
    end
  end
end
