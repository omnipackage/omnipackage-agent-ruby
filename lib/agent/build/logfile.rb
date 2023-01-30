# frozen_string_literal: true

require 'fileutils'

module Agent
  class Build
    class Logfile
      attr_reader :file, :path

      def initialize(path)
        ::FileUtils.rm(path) if ::File.exist?(path)
        @path = path
        @file = ::File.open(path, 'a+')
        at_exit { close }
      end

      def puts(line)
        file.puts(line)
      end

      def write(message)
        file.write(message)
      end

      def close
        file.close
      end
    end
  end
end
