# frozen_string_literal: true

require 'logger'

module OmnipackageAgent
  module Logging
    class Formatter < ::Logger::Formatter
      attr_reader :tagging

      def initialize(tags: [])
        @tagging = tags.any? ? "[#{tags.join(', ')}] " : ''
        super()
      end

      def call(severity, datetime, progname, msg)
        if progname == 'container'
          msg
        else
          progname = progname.nil? ? ' ' : " #{progname} | "
          "#{tagging}[#{severity[0]} #{datetime.utc.strftime('%d.%m.%Y %H:%M:%S')}]#{progname}#{msg}\n"
        end
      end
    end
  end
end
