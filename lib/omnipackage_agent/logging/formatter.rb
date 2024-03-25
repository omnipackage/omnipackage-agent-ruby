# frozen_string_literal: true

require 'logger'

module OmnipackageAgent
  module Logging
    class Formatter < ::Logger::Formatter
      attr_reader :tags, :filters

      def initialize(tags: [], filters: [])
        @tags = tags
        @filters = filters
        super()
      end

      def call(severity, datetime, progname, msg)
        filters.each { |substr| msg.gsub!(substr, '***') }
        if progname == 'container'
          msg
        else
          progname = progname.nil? ? ' ' : " #{progname} | "
          "#{tagging}[#{severity[0]} #{datetime.utc.strftime('%d.%m.%Y %H:%M:%S')}]#{progname}#{msg}\n"
        end
      end

      def add_filters(new_filters)
        self.class.new(filters: filters + new_filters)
      end

      private

      def tagging
        @tagging ||= tags.any? ? "[#{tags.join(', ')}] " : ''
      end
    end
  end
end
