# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'logger'
require 'stringio'

require 'agent/utils/subprocess'
require 'agent/distro'
require 'agent/image_cache'
require 'agent/rpm/specfile'
require 'agent/deb/debian_folder'
require 'agent/utils/path'
require 'agent/build/logfile'
require 'agent/build/output'
require 'agent/logging/multioutput'

module Agent
  class Build
    attr_reader :build_conf, :distro, :image_cache

    def initialize(build_conf)
      @build_conf = build_conf
      @distro = ::Agent::Distro.new(build_conf.fetch(:distro))
      @log_string = ::StringIO.new
      @logger = ::Logger.new(::Agent::Logging::Multioutput.new($stdout, log_string), formatter: ::Agent::Logging::Formatter.new)
      @image_cache = ::Agent::ImageCache.new(logger: logger)
    end

    def run(source_path, job_variables)
      logger.info("starting build for #{distro.name} in #{source_path}, variables: #{job_variables}")

      success, artefacts, logfile = if distro.rpm?
                                      rpm(source_path, job_variables)
                                    elsif distro.deb?
                                      deb(source_path, job_variables)
                                    else
                                      raise "distro #{distro} not supported"
                                    end

      if success
        image_cache.commit(container_name)
        logger.info("successfully finished build for #{distro.name}, artefacts: #{artefacts}, log: #{logfile.path}")
      else
        logger.error("failed build for #{distro.name}")
      end
      image_cache.rm(container_name)
      logfile.write(log_string.string)
      logfile.close
    end

    private

    attr_reader :log_string, :logger

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
        #{::Agent.runtime} run --name #{container_name} --entrypoint /bin/sh #{mount_cli} #{image} -c "#{commands.join(' && ')}"
      CLI
    end

    def execute(cli)
      ::Agent::Utils::Subprocess.new(logger: logger).execute(cli) do |output_line|
        logger.info('container') { output_line }
      end&.success?
    end

    def rpm(source_path, job_variables)
      version = job_variables.fetch(:version)

      specfile_path_template_path = build_conf.fetch(:rpm).fetch(:spec_template)

      specfile = ::Agent::Rpm::Specfile.new(::Agent::Utils::Path.mkpath(source_path, specfile_path_template_path))
      rpmbuild_folder_name = "rpmbuild-#{specfile.name}-#{distro.name}"
      rpmbuild_path = ::Agent::Utils::Path.mkpath(::Agent.build_dir, rpmbuild_folder_name)
      ::FileUtils.mkdir_p(rpmbuild_path)

      source_folder_name = "#{specfile.name}-#{version}"
      specfile_name = "#{source_folder_name}-#{distro.name}.spec"

      template_params = build_conf.merge(job_variables).merge(source_folder_name: source_folder_name)
      specfile.save(::Agent::Utils::Path.mkpath(::Agent.build_dir, rpmbuild_folder_name, specfile_name), template_params)

      commands = distro.setup(build_deps) + [
        'rpmdev-setuptree',
        "cp -R /source /root/rpmbuild/SOURCES/#{source_folder_name}",
        'cd /root/rpmbuild/SOURCES/',
        "tar -cvzf #{source_folder_name}.tar.gz #{source_folder_name}/",
        "cd /root/rpmbuild/SOURCES/#{source_folder_name}/",
        "QA_RPATHS=$(( 0x0001|0x0010 )) rpmbuild --clean -bb /root/rpmbuild/#{specfile_name}"
      ]

      mounts = {
        source_path.to_s    => '/source',
        rpmbuild_path.to_s  => '/root/rpmbuild'
      }
      build_success = execute(build_cli(mounts, commands))
      logfile = ::Agent::Build::Logfile.new(::Agent::Utils::Path.mkpath(rpmbuild_path, 'build.log'))
      artifacts = ::Dir[::Agent::Utils::Path.mkpath(rpmbuild_path, 'RPMS', '**', '*.rpm')]
      [build_success, artifacts, logfile]
    end

    def deb(source_path, job_variables)
      # version = job_variables.fetch(:version)

      debian_folder_template_path = build_conf.fetch(:deb).fetch(:debian_templates)
      debian_folder = ::Agent::Deb::DebianFolder.new(::Agent::Utils::Path.mkpath(source_path, debian_folder_template_path))
      build_folder_name = "debuild-#{debian_folder.name}-#{distro.name}"

      build_path = ::Agent::Utils::Path.mkpath(::Agent.build_dir, build_folder_name, 'build')
      output_path = ::Agent::Utils::Path.mkpath(::Agent.build_dir, build_folder_name, 'output')
      ::FileUtils.mkdir_p(build_path)
      ::FileUtils.mkdir_p(output_path)

      template_params = build_conf.merge(job_variables)
      debian_folder.save(::Agent::Utils::Path.mkpath(build_path, 'debian'), template_params)

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

      build_success = execute(build_cli(mounts, commands))
      logfile = ::Agent::Build::Logfile.new(::Agent::Utils::Path.mkpath(output_path, 'build.log'))
      artifacts = ::Dir[::Agent::Utils::Path.mkpath(output_path, '*.deb')]
      [build_success, artifacts, logfile]
    end
  end
end
