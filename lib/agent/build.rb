# frozen_string_literal: true

require_relative 'subprocess'

require 'fileutils'
require 'pathname'

module Agent
  class Build
    attr_reader :build_conf

    def initialize(build_conf)
      @build_conf = build_conf
    end

    def run(source_path)
      distro = build_conf.distro
      rpmbuild_path = Pathname.new('/tmp').join('build-package-ipsum', "rpmbuild-#{distro}").to_s
      FileUtils.mkdir_p(rpmbuild_path)

      specfile_path_template_path = build_conf.rpm.spec_template
      build_deps = build_conf.build_dependencies
      specfile = Agent::Rpm::Specfile.new(Pathname.new(source_path).join(specfile_path_template_path))
      version = '1.0.22'
      source_folder_name = "mpz-#{version}"
      specfile_name = "#{source_folder_name}-#{distro}.spec"
      specfile.save(Pathname.new(source_path).join(specfile_name), {
        version: version,
        build_dependencies: build_deps,
        source_folder_name: source_folder_name
      })

      commands = [
        'zypper in -y -t pattern devel_basis devel_rpm_build',
        'zypper in -y rpmdevtools',
        "zypper in -y #{build_deps.join(' ')}",
        'rpmdev-setuptree',
        "cp -R /source /root/rpmbuild/SOURCES/#{source_folder_name}",
        'cd /root/rpmbuild/SOURCES/',
        "tar -cvzf #{source_folder_name}.tar.gz #{source_folder_name}/",
        "cd /root/rpmbuild/SOURCES/#{source_folder_name}/",
        "rpmbuild -ba /root/rpmbuild/SOURCES/#{source_folder_name}/#{specfile_name}"
      ]

      cli = <<~CLI
        docker run --rm --entrypoint /bin/sh \
          --mount type=bind,source=#{source_path},target=/source \
          --mount type=bind,source=#{rpmbuild_path},target=/root/rpmbuild \
          #{build_conf.image} \
          -c "#{commands.join(' && ')}"
      CLI

      Agent::Subprocess.execute(cli) { |output_line| puts(output_line) }
    end
  end
end
