# frozen_string_literal: true

module Agent
  class Distro
    attr_reader :name, :config

    def initialize(distro)
      @name = distro
      @config = CONFIGS.fetch(distro)
    end

    def setup(build_dependencies)
      config.fetch(:setup).map do |command|
        format(command, build_dependencies: build_dependencies.join(' '))
      end
    end

    def image
      config.fetch(:image)
    end

    def rpm?
      config.fetch(:package_type) == 'rpm'
    end

    def deb?
      config.fetch(:package_type) == 'deb'
    end

    CONFIGS = {
      'opensuse_15.3' => {
        package_type: 'rpm',
        image: 'opensuse/leap:15.3',
        setup: [
          'zypper --non-interactive install -y -t pattern devel_basis devel_rpm_build',
          'zypper --non-interactive install -y rpmdevtools %{build_dependencies}'
        ]
      },
      'opensuse_15.4' => {
        package_type: 'rpm',
        image: 'opensuse/leap:15.3',
        setup: [
          'zypper --non-interactive install -y -t pattern devel_basis devel_rpm_build',
          'zypper --non-interactive install -y rpmdevtools %{build_dependencies}'
        ]
      },
      'opensuse_tumbleweed' => {
        package_type: 'rpm',
        image: 'opensuse/tumbleweed',
        setup: [
          'zypper --non-interactive install -y -t pattern devel_basis devel_rpm_build',
          'zypper --non-interactive install -y rpmdevtools %{build_dependencies}'
        ]
      },
      'fedora_38' => {
        package_type: 'rpm',
        image: 'fedora:38',
        setup: [
          'dnf install -y rpmdevtools tar %{build_dependencies}'
        ]
      },
      'debian_bullseye' => {
        package_type: 'deb',
        image: 'debian:bullseye',
        setup: [
          'apt-get update',
          'apt-get install -y build-essential debhelper %{build_dependencies}'
        ]
      },
      'ubuntu_22.04' => {
        package_type: 'deb',
        image: 'ubuntu:22.04',
        setup: [
          'apt-get update',
          'apt-get install -y build-essential debhelper %{build_dependencies}'
        ]
      },
      'ubuntu_22.10' => {
        package_type: 'deb',
        image: 'ubuntu:22.10',
        setup: [
          'apt-get update',
          'apt-get install -y build-essential debhelper %{build_dependencies}'
        ]
      }

    }.freeze
    private_constant :CONFIGS
  end
end
