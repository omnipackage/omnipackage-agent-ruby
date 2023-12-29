# frozen_string_literal: true

require 'pathname'
require 'fileutils'
require 'time'

require 'omnipackage_agent/utils/template'
require 'omnipackage_agent/utils/path'

module OmnipackageAgent
  module Build
    module Deb
      class DebianFolder
        attr_reader :debian_folder_path

        def initialize(debian_folder_path)
          @debian_folder_path = debian_folder_path
        end

        def name
          file = if ::File.exist?(mkpath_rel("control#{template_ext}"))
                   ::File.read(mkpath_rel("control#{template_ext}"))
                 elsif ::File.exist?(mkpath_rel('control'))
                   ::File.read(mkpath_rel('control'))
                 else
                   raise "no control file in #{debian_folder_path}"
                 end

          /[Ss]ource:(.+)/.match(file)[1].strip
        end

        def render(params_hash) # rubocop: disable Metrics/AbcSize
          ::Dir.foreach(debian_folder_path).each_with_object({}) do |fname, result_hash|
            next if ['.', '..'].include?(fname)

            if fname.end_with?(template_ext)
              output_file_path = ::OmnipackageAgent::Utils::Path.mkpath(debian_folder_path, fname)
              result_hash[fname.chomp(template_ext)] = ::OmnipackageAgent::Utils::Template.new(output_file_path).render(params_hash)
            else
              result_hash[fname] = ::File.read(mkpath_rel(fname))
            end
          end
        end

        def save(path, params_hash)
          ::FileUtils.mkdir_p(path)
          render(params_hash).each do |file, content|
            ::File.write(::OmnipackageAgent::Utils::Path.mkpath(path, file), content)
          end
        end

        private

        def mkpath_rel(fname)
          ::OmnipackageAgent::Utils::Path.mkpath(debian_folder_path, fname)
        end

        def template_ext
          ::OmnipackageAgent::Utils::Template.file_extension
        end
      end
    end
  end
end
