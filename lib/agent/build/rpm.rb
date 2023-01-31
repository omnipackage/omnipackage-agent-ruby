# frozen_string_literal: true

require 'fileutils'

require 'agent/distro'
require 'agent/rpm/specfile'
require 'agent/utils/path'
require 'agent/build/base_package'

module Agent
  class Build
    class Rpm < ::Agent::Build::BasePackage
      def artefacts
        @artefacts ||= ::Dir[::Agent::Utils::Path.mkpath(output_path, 'RPMS', '**', '*.rpm')]
      end

      private

      def setup # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
        specfile_path_template_path = build_conf.fetch(:rpm).fetch(:spec_template)

        specfile = ::Agent::Rpm::Specfile.new(::Agent::Utils::Path.mkpath(source_path, specfile_path_template_path))
        rpmbuild_folder_name = "rpmbuild-#{specfile.name}-#{distro.name}"
        rpmbuild_path = ::Agent::Utils::Path.mkpath(::Agent.build_dir, rpmbuild_folder_name)
        ::FileUtils.mkdir_p(rpmbuild_path)
        @output_path = rpmbuild_path

        source_folder_name = "#{specfile.name}-#{version}"
        specfile_name = "#{source_folder_name}-#{distro.name}.spec"

        template_params = build_conf.merge(job_variables).merge(source_folder_name: source_folder_name)
        specfile.save(::Agent::Utils::Path.mkpath(::Agent.build_dir, rpmbuild_folder_name, specfile_name), template_params)

        @commands = distro.setup(build_deps) + [
          'rpmdev-setuptree',
          "cp -R /source /root/rpmbuild/SOURCES/#{source_folder_name}",
          'cd /root/rpmbuild/SOURCES/',
          "tar -cvzf #{source_folder_name}.tar.gz #{source_folder_name}/",
          "cd /root/rpmbuild/SOURCES/#{source_folder_name}/",
          "QA_RPATHS=$(( 0x0001|0x0010 )) rpmbuild --clean -bb /root/rpmbuild/#{specfile_name}"
        ]

        @mounts = {
          source_path.to_s    => '/source',
          rpmbuild_path.to_s  => '/root/rpmbuild'
        }
      end
    end
  end
end
