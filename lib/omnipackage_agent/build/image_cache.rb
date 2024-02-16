# frozen_string_literal: true

require 'digest/sha1'

require 'omnipackage_agent/utils/subprocess'

module OmnipackageAgent
  class Build
    class ImageCache
      attr_reader :subprocess, :config, :default_image, :container_name

      def initialize(subprocess:, config:, default_image:, distro_name:, deps:)
        @config = config
        @subprocess = subprocess
        @default_image = default_image
        @container_name = generate_container_name(distro_name, deps)
      end

      def image
        if subprocess.execute("#{config.container_runtime} image inspect #{container_name}")&.success?
          container_name
        else
          default_image
        end
      end

      def commit_cli
        "#{config.container_runtime} commit #{container_name} #{container_name}"
      end

      def rm_cli
        "#{config.container_runtime} rm -f #{container_name}"
      end

      private

      def generate_container_name(distro_name, deps)
        "omnipackage-agent-#{distro_name}-#{::Digest::SHA1.hexdigest(deps.sort.join)}"
      end
    end
  end
end
