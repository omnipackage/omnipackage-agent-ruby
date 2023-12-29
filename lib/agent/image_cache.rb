# frozen_string_literal: true

require 'digest/sha1'

require 'agent/utils/subprocess'

module Agent
  class ImageCache
    attr_reader :logger, :subprocess

    def initialize(logger: ::Agent.logger)
      @logger = logger
      @subprocess = ::Agent::Utils::Subprocess.new(logger: logger)
    end

    def generate_container_name(distro_name, build_deps)
      "omnipackage-agent-#{distro_name}-#{::Digest::SHA1.hexdigest(build_deps.sort.join)}"
    end

    def image(container_name, default_image)
      if subprocess.execute("#{::Agent.config.container_runtime} image inspect #{container_name}")&.success?
        container_name
      else
        default_image
      end
    end

    def commit(container_name, &block)
      subprocess.execute("#{::Agent.config.container_runtime} commit #{container_name} #{container_name}", &block)
    end

    def rm(container_name, &block)
      subprocess.execute("#{::Agent.config.container_runtime} rm -f #{container_name}", &block)
    end
  end
end
