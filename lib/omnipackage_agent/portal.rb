# frozen_string_literal: true

require 'fileutils'

require 'omnipackage_agent/distro'

module OmnipackageAgent
  class Portal
    attr_reader :config, :mountpoint

    def initialize(config:)
      @config = config
      @mountpoint = "/#{::File.basename(config.build_dir)}"
      ::FileUtils.mkdir_p(config.build_dir)
    end

    def call(distro_name)
      distro = ::OmnipackageAgent::Distro.new(distro_name)
      system("#{config.container_runtime} run -it --rm --mount type=bind,source=#{config.build_dir},target=#{mountpoint},readonly -w #{mountpoint} #{distro.image}")
    end
  end
end
