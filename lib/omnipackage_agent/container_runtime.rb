# frozen_string_literal: true

module OmnipackageAgent
  module ContainerRuntime
    module_function

    AVAILABLE = %w[podman docker].freeze

    def auto_detect
      AVAILABLE.find { |cmd| system("#{cmd} --version > /dev/null 2>&1") } || (raise "you have to install #{AVAILABLE.join(' or ')}")
    end
  end
end
