# frozen_string_literal: true

require 'fileutils'

require 'agent/distro'
require 'agent/deb/debian_folder'
require 'agent/utils/path'
require 'agent/build/base_package'

module Agent
  class Build
    class Deb < ::Agent::Build::BasePackage
      def artefacts
        @artefacts ||= ::Dir[::Agent::Utils::Path.mkpath(output_path, '*.deb')]
      end

      private

      def setup # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
        debian_folder_template_path = build_conf.fetch(:deb).fetch(:debian_templates)
        debian_folder = ::Agent::Deb::DebianFolder.new(::Agent::Utils::Path.mkpath(source_path, debian_folder_template_path))
        build_folder_name = "debuild-#{debian_folder.name}-#{distro.name}"

        build_path = ::Agent::Utils::Path.mkpath(::Agent.build_dir, build_folder_name, 'build')
        @output_path = ::Agent::Utils::Path.mkpath(::Agent.build_dir, build_folder_name, 'output')
        ::FileUtils.mkdir_p(build_path)
        ::FileUtils.mkdir_p(output_path)

        template_params = build_conf.merge(job_variables)
        debian_folder.save(::Agent::Utils::Path.mkpath(build_path, 'debian'), template_params)

        @commands = distro.setup(build_deps) + [
          'cp -R /source/* /output/build/',
          'cd /output/build',
          'dpkg-buildpackage -b -tc',
          'rm -rf /output/build/*'
        ]

        @mounts = {
          source_path.to_s  => '/source',
          build_path.to_s   => '/output/build',
          output_path.to_s  => '/output/'
        }
      end
    end
  end
end
