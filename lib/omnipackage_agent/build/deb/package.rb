# frozen_string_literal: true

require 'fileutils'

require 'omnipackage_agent/distro'
require 'omnipackage_agent/build/deb/debian_folder'
require 'omnipackage_agent/utils/path'
require 'omnipackage_agent/build/base_package'

module OmnipackageAgent
  class Build
    module Deb
      class Package < ::OmnipackageAgent::Build::BasePackage
        def artefacts
          @artefacts ||= ::Dir[::OmnipackageAgent::Utils::Path.mkpath(output_path, '*.deb')]
        end

        private

        def setup # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
          debian_folder_template_path = build_conf.fetch(:deb).fetch(:debian_templates)
          debian_folder = ::OmnipackageAgent::Build::Deb::DebianFolder.new(::OmnipackageAgent::Utils::Path.mkpath(source_path, debian_folder_template_path))
          build_folder_name = "#{name}-#{distro.name}"

          build_path = ::OmnipackageAgent::Utils::Path.mkpath(build_dir, build_folder_name, 'build')
          @output_path = ::OmnipackageAgent::Utils::Path.mkpath(build_dir, build_folder_name, 'output')
          ::FileUtils.mkdir_p(build_path)
          ::FileUtils.mkdir_p(output_path)

          template_params = build_conf.merge(job_variables)
          debian_folder.save(::OmnipackageAgent::Utils::Path.mkpath(build_path, 'debian'), template_params)

          @commands = distro.setup(build_deps) + [
            before_build_script('/source'),
            'cp -R /source/. /output/build/',
            'cd /output/build',
            'DEB_BUILD_OPTIONS=noddebs dpkg-buildpackage -b -tc'
            # 'rm -rf /output/build/*'
          ].compact

          @mounts = {
            source_path.to_s  => '/source',
            build_path.to_s   => '/output/build',
            output_path.to_s  => '/output/'
          }
        end
      end
    end
  end
end
