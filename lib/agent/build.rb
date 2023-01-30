# frozen_string_literal: true

require 'fileutils'
require 'pathname'

require 'agent/utils/subprocess'
require 'agent/distro'
require 'agent/image_cache'
require 'agent/rpm/specfile'
require 'agent/deb/debian_folder'
require 'agent/utils/path'

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

      build_success, artifacts = if distro.rpm?
        rpm(source_path, job_variables)
      elsif distro.deb?
        deb(source_path, job_variables)
      else
        raise "distro #{distro} not supported"
      end

      if build_success
        image_cache.commit(container_name)
        Agent.logger.info("successfully finished build for #{distro.name}, artifacts: #{artifacts}")
      else
        Agent.logger.info("failed build for #{distro.name}")
      end
      image_cache.rm(container_name)
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

    def build_cli(mounts, commands)
      mount_cli = mounts.map do |from, to|
        "--mount type=bind,source=#{from},target=#{to}"
      end.join(' ')

      <<~CLI
        #{Agent.runtime} run --name #{container_name} --entrypoint /bin/sh #{mount_cli} #{image} -c "#{commands.join(' && ')}"
      CLI
    end

    def rpm(source_path, job_variables)
      version = job_variables.fetch(:version)

      specfile_path_template_path = build_conf.fetch(:rpm).fetch(:spec_template)
      build_src_rpm = build_conf[:rpm][:build_srcrpm] || false

      specfile = Agent::Rpm::Specfile.new(Agent::Utils::Path.mkpath(source_path, specfile_path_template_path))
      rpmbuild_folder_name = "rpmbuild-#{specfile.name}-#{distro.name}"
      rpmbuild_path = Agent::Utils::Path.mkpath(Agent.build_dir, rpmbuild_folder_name)
      FileUtils.mkdir_p(rpmbuild_path)

      source_folder_name = "#{specfile.name}-#{version}"
      specfile_name = "#{source_folder_name}-#{distro.name}.spec"

      template_params = build_conf.merge(job_variables).merge(source_folder_name: source_folder_name)
      specfile.save(Agent::Utils::Path.mkpath(Agent.build_dir, rpmbuild_folder_name, specfile_name), template_params)

      commands = distro.setup(build_deps) + [
        'rpmdev-setuptree',
        "cp -R /source /root/rpmbuild/SOURCES/#{source_folder_name}",
        'cd /root/rpmbuild/SOURCES/',
        "tar -cvzf #{source_folder_name}.tar.gz #{source_folder_name}/",
        "cd /root/rpmbuild/SOURCES/#{source_folder_name}/",
        # "rpmbuild #{build_debuginfo ? '' : '--define "debug_package %{nil}"'} -b#{build_src_rpm ? 'a' : 'b'} /root/rpmbuild/SOURCES/#{source_folder_name}/#{specfile_name}"
        "QA_RPATHS=$(( 0x0001|0x0010 )) rpmbuild --clean -b#{build_src_rpm ? 'a' : 'b'} /root/rpmbuild/#{specfile_name}"
      ]

      mounts = {
        source_path.to_s    => '/source',
        rpmbuild_path.to_s  => '/root/rpmbuild'
      }

      artifact_regex = /Wrote: (.+\.rpm)/
      artifacts = []
      build_success = Agent::Utils::Subprocess.execute(build_cli(mounts, commands)) do |output_line|
        match = artifact_regex.match(output_line)
        artifacts << match[1].strip if match
        puts(output_line)
      end&.success?

      artifacts.map! do |path|
        mount_map = mounts.find { |from, to| path.start_with?(to) }
        path.gsub(mount_map[1], mount_map[0])
      end
      [build_success, artifacts]
    end

    def deb(source_path, job_variables)
      version = job_variables.fetch(:version)

      debian_folder_template_path = build_conf.fetch(:deb).fetch(:debian_templates)
      debian_folder = Agent::Deb::DebianFolder.new(Agent::Utils::Path.mkpath(source_path, debian_folder_template_path))
      build_folder_name = "debuild-#{debian_folder.name}-#{distro.name}"

      build_path = Agent::Utils::Path.mkpath(Agent.build_dir, build_folder_name, 'build')
      output_path = Agent::Utils::Path.mkpath(Agent.build_dir, build_folder_name, 'output')
      FileUtils.mkdir_p(build_path)
      FileUtils.mkdir_p(output_path)

      template_params = build_conf.merge(job_variables)
      debian_folder.save(Agent::Utils::Path.mkpath(build_path, 'debian'), template_params)

      commands = distro.setup(build_deps) + [
        'cp -R /source/* /output/build/',
        'cd /output/build',
        'dpkg-buildpackage -b -tc',
        'rm -rf /output/build/*'
      ]

      mounts = {
        source_path.to_s  => '/source',
        build_path.to_s   => '/output/build',
        output_path.to_s  => '/output/'
      }
      build_success = Agent::Utils::Subprocess.execute(build_cli(mounts, commands)) do |output_line|
        puts(output_line)
      end&.success?

      artifacts = Dir["#{output_path}/*.deb"]
      [build_success, artifacts]
    end

  end
end
