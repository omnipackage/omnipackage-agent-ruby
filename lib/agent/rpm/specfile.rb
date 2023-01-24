# frozen_string_literal: true

require_relative '../template'

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

      def render(params)
        Agent::Template.new(params).render(template)
      end

      def save(path, params)
        File.write(path, render(params))
        path
      end
    end
  end
end
