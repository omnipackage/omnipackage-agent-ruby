# frozen_string_literal: true

require 'digest/sha1'

module OmnipackageAgent
  class ImageCache
    attr_reader :container_runtime

    def initialize(container_runtime:)
      @container_runtime = container_runtime
    end

    def generate_container_name(distro_name, build_deps)
      "omnipackage-agent-#{distro_name}-#{::Digest::SHA1.hexdigest(build_deps.sort.join)}"
    end

    def image(container_name, default_image)
      if container_runtime.execute("image inspect #{container_name}")&.success?
        container_name
      else
        default_image
      end
    end

    def commit(container_name)
      container_runtime.execute("commit #{container_name} #{container_name}")
    end

    def rm(container_name)
      container_runtime.execute("rm -f #{container_name}")
    end
  end
end
