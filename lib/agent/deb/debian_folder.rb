# frozen_string_literal: true

require 'pathname'
require 'fileutils'
require 'time'

require 'agent/utils/template'

module Agent
  module Deb
    class DebianFolder
      attr_reader :debian_folder_path

      def initialize(debian_folder_path)
        @debian_folder_path = debian_folder_path
      end

      def name
        file = if File.exist?(mkpath_rel('control.erb'))
                 File.read(mkpath_rel('control.erb'))
               elsif File.exist?(mkpath_rel('control'))
                 File.read(mkpath_rel('control'))
               else
                 raise "no control file in #{debian_folder_path}"
               end

        /[Ss]ource:(.+)/.match(file)[1].strip
      end

      def render(params_hash)
        result_hash = {}
        Dir.foreach(debian_folder_path) do |fname|
          next if fname == '.' || fname == '..'
          if fname.end_with?('.erb')
            result_hash[fname.chomp('.erb')] = Agent::Utils::Template.new(mkpath(debian_folder_path, fname)).render(params_hash)
          else
            result_hash[fname] = File.read(mkpath_rel(fname))
          end
        end
        result_hash
      end

      def save(path, params_hash)
        FileUtils.mkdir_p(path)
        render(params_hash).each do |file, content|
          File.write(mkpath(path, file), content)
        end
      end

      private

      def mkpath_rel(fname)
        mkpath(debian_folder_path, fname)
      end

      def mkpath(*parts)
        Pathname.new(parts[0]).join(*parts[1..-1])
      end
    end
  end
end
