# frozen_string_literal: true

require 'digest/sha1'

module OmnipackageAgent
  class ImageCache
    attr_reader :container_runtime, :default_image, :container_name

    def initialize(container_runtime:, default_image:, distro_name:, build_deps:)
      @container_runtime = container_runtime
      @default_image = default_image
      @container_name = generate_container_name(distro_name, build_deps)
    end

    def image
      if container_runtime.execute("#{container_runtime.executable} image inspect #{container_name}", lock_key: nil)&.success?
        container_name
      else
        default_image
      end
    end

    def commit_cli
      "#{container_runtime.executable} commit #{container_name} #{container_name}"
    end

    def rm_cli
      "#{container_runtime.executable} rm -f #{container_name}"
    end

    private

    def generate_container_name(distro_name, build_deps)
      "omnipackage-agent-#{distro_name}-#{::Digest::SHA1.hexdigest(build_deps.sort.join)}"
    end
  end
end
