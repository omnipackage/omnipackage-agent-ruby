# frozen_string_literal: true

require 'logger'

module OmnipackageAgent
  module Logging
    class Formatter < ::Logger::Formatter
      def call(severity, datetime, progname, msg)
        if progname == 'container'
          msg
        else
          progname = progname.nil? ? ' ' : " #{progname} | "
          "[#{severity[0]} #{datetime.utc.strftime('%d.%m.%Y %H:%M:%S')}]#{progname}#{msg}\n"
        end
      end
    end
  end
end
