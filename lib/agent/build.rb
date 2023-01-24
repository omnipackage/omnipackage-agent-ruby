# frozen_string_literal: true

require_relative 'utils/subprocess'
require_relative 'distro'

require 'fileutils'
require 'pathname'

module Agent
  class Build
    attr_reader :build_conf, :distro

    def initialize(build_conf)
      @build_conf = build_conf
      @distro = Agent::Distro.new(build_conf.fetch(:distro))
    end

    def image
      build_conf[:image] || distro.image
    end

    def build_deps
      build_conf.fetch(:build_dependencies)
    end

    def run(source_path, job_variables)
      Agent.logger.info("starting build for #{distro.name} in #{source_path}, variables: #{job_variables}")

      if distro.rpm?
        rpm(source_path, job_variables)
      elsif distro.deb?
      else
        raise "distro #{distro} not supported"
      end

      Agent.logger.info("finished build for #{distro.name} in #{source_path}")
    end

    private

    def rpm(source_path, job_variables)
      version = job_variables.fetch(:version)

      specfile_path_template_path = build_conf.fetch(:rpm).fetch(:spec_template)
      build_src_rpm = build_conf[:rpm][:build_srcrpm] || false
      build_debuginfo =  build_conf[:rpm][:build_debuginfo] || false

      rpmbuild_path = Pathname.new(Agent.build_dir).join("rpmbuild-#{distro.name}")
      FileUtils.mkdir_p(rpmbuild_path)
      specfile = Agent::Rpm::Specfile.new(Pathname.new(source_path).join(specfile_path_template_path))
      source_folder_name = "#{specfile.name}-#{version}"
      specfile_name = "#{source_folder_name}-#{distro.name}.spec"
      specfile.save(Pathname.new(source_path).join(specfile_name), {
                      version: version,
                      build_dependencies: build_deps,
                      source_folder_name: source_folder_name
                    })

      commands = distro.setup(build_deps) + [
        'rm -rf /root/rpmbuild/*',
        'rpmdev-setuptree',
        "cp -R /source /root/rpmbuild/SOURCES/#{source_folder_name}",
        'cd /root/rpmbuild/SOURCES/',
        "tar -cvzf #{source_folder_name}.tar.gz #{source_folder_name}/",
        "cd /root/rpmbuild/SOURCES/#{source_folder_name}/",
        "rpmbuild #{build_debuginfo ? '' : '--define "debug_package %{nil}"'} -b#{build_src_rpm ? 'a' : 'b'} /root/rpmbuild/SOURCES/#{source_folder_name}/#{specfile_name}"
      ]

      cli = <<~CLI
        docker run --rm --entrypoint /bin/sh \
          --mount type=bind,source=#{source_path},target=/source \
          --mount type=bind,source=#{rpmbuild_path},target=/root/rpmbuild \
          #{image} \
          -c "#{commands.join(' && ')}"
      CLI

      Agent::Utils::Subprocess.execute(cli) { |output_line| puts(output_line) }
    end
  end
end
