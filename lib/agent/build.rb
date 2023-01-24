# frozen_string_literal: true

require_relative 'utils/subprocess'
require_relative 'distro'
require_relative 'image_cache'

require 'fileutils'
require 'pathname'

module Agent
  class Build
    attr_reader :build_conf, :distro, :image_cache

    def initialize(build_conf)
      @build_conf = build_conf
      @distro = Agent::Distro.new(build_conf.fetch(:distro))
      @image_cache = Agent::ImageCache.new
    end

    def run(source_path, job_variables)
      Agent.logger.info("starting build for #{distro.name} in #{source_path}, variables: #{job_variables}")

      artifacts = if distro.rpm?
        rpm(source_path, job_variables)
      elsif distro.deb?
      else
        raise "distro #{distro} not supported"
      end

      finalize
      Agent.logger.info("finished build for #{distro.name} in #{source_path}, artifacts: #{artifacts}")
    end

    private

    def build_deps
      build_conf.fetch(:build_dependencies)
    end

    def container_name
      @container_name ||= image_cache.generate_container_name(distro.name, build_deps)
    end

    def image
      @image ||= image_cache.image(container_name, build_conf[:image] || distro.image)
    end

    def finalize
      image_cache.commit_rm(container_name)
    end

    def rpm(source_path, job_variables)
      version = job_variables.fetch(:version)

      specfile_path_template_path = build_conf.fetch(:rpm).fetch(:spec_template)
      build_src_rpm = build_conf[:rpm][:build_srcrpm] || false
      build_debuginfo =  build_conf[:rpm][:build_debuginfo] || false

      specfile = Agent::Rpm::Specfile.new(Pathname.new(source_path).join(specfile_path_template_path))
      rpmbuild_path = Pathname.new(Agent.build_dir).join("rpmbuild-#{specfile.name}-#{distro.name}")
      FileUtils.mkdir_p(rpmbuild_path)
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
        # "rpmbuild #{build_debuginfo ? '' : '--define "debug_package %{nil}"'} -b#{build_src_rpm ? 'a' : 'b'} /root/rpmbuild/SOURCES/#{source_folder_name}/#{specfile_name}"
        "rpmbuild -b#{build_src_rpm ? 'a' : 'b'} /root/rpmbuild/SOURCES/#{source_folder_name}/#{specfile_name}"
      ]

      mounts = [
        [source_path.to_s, '/source'],
        [rpmbuild_path.to_s, '/root/rpmbuild']
      ]
      mount_cli = mounts.map do |from, to|
        "--mount type=bind,source=#{from},target=#{to}"
      end.join(' ')

      cli = <<~CLI
        #{Agent.runtime} run --name #{container_name} --entrypoint /bin/sh #{mount_cli} #{image} -c "#{commands.join(' && ')}"
      CLI

      artifact_regex = /Wrote: (.+\.rpm)/
      artifacts = []
      Agent::Utils::Subprocess.execute(cli) do |output_line|
        match = artifact_regex.match(output_line)
        artifacts << match[1].strip if match
        puts(output_line)
      end

      artifacts.map do |path|
        mount_map = mounts.find { |from, to| path.start_with?(to) }
        path.gsub(mount_map[1], mount_map[0])
      end
    end
  end
end
