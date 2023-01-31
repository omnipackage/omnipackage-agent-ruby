# frozen_string_literal: true

require 'pathname'
require 'fileutils'
require 'time'

require 'agent/utils/template'
require 'agent/utils/path'

module Agent
  module Build
    module Deb
      class DebianFolder
        attr_reader :debian_folder_path

        def initialize(debian_folder_path)
          @debian_folder_path = debian_folder_path
        end

        def name
          file = if ::File.exist?(mkpath_rel('control.erb'))
                   ::File.read(mkpath_rel('control.erb'))
                 elsif ::File.exist?(mkpath_rel('control'))
                   ::File.read(mkpath_rel('control'))
                 else
                   raise "no control file in #{debian_folder_path}"
                 end

          /[Ss]ource:(.+)/.match(file)[1].strip
        end

        def render(params_hash)
          ::Dir.foreach(debian_folder_path).each_with_object({}) do |fname, result_hash|
            next if ['.', '..'].include?(fname)

            if fname.end_with?('.erb')
              output_file_path = ::Agent::Utils::Path.mkpath(debian_folder_path, fname)
              result_hash[fname.chomp('.erb')] = ::Agent::Utils::Template.new(output_file_path).render(params_hash)
            else
              result_hash[fname] = ::File.read(mkpath_rel(fname))
            end
          end
        end

        def save(path, params_hash)
          ::FileUtils.mkdir_p(path)
          render(params_hash).each do |file, content|
            ::File.write(::Agent::Utils::Path.mkpath(path, file), content)
          end
        end

        private

        def mkpath_rel(fname)
          ::Agent::Utils::Path.mkpath(debian_folder_path, fname)
        end
      end
    end
  end
end
