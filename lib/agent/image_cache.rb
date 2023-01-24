# frozen_string_literal: true

require_relative 'utils/subprocess'

require 'digest/sha1'

module Agent
  class ImageCache
    def generate_container_name(distro_name, build_deps)
      "package-ipsum-#{distro_name}-#{Digest::SHA1.hexdigest(build_deps.sort.join)}"
    end

    def image(container_name, default_image)
      if Agent::Utils::Subprocess.execute("#{Agent.runtime} image inspect #{container_name}")&.success?
        container_name
      else
        default_image
      end
    end

    def commit_rm(container_name, &block)
      Agent::Utils::Subprocess.execute("#{Agent.runtime} commit #{container_name} #{container_name}", &block)
      Agent::Utils::Subprocess.execute("#{Agent.runtime} rm #{container_name}", &block)
    end
  end
end
