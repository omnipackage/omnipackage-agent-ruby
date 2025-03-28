# frozen_string_literal: true

require 'omnipackage_agent/utils/path'

module OmnipackageAgent
  class Build
    class Lock
      def initialize(config:, key:, timeout: 30_000)
        @config = config
        @timeout = timeout
        @lockfile = build_lockfile(key)
      end

      def to_cli
        "flock --verbose --timeout #{timeout} #{lockfile} --command"
      end

      def extract_wait_time(logstring)
        logstring.lines.inject(0) do |acc, elem|
          match = /flock: getting lock took (\d+\.\d+) seconds/.match(elem.unpack('C*').pack('U*'))
          if match && match[1]
            acc + match[1].to_f
          else
            acc
          end
        end
      end

      private

      attr_reader :lockfile, :config, :timeout

      def build_lockfile(key)
        ::FileUtils.mkdir_p(config.lockfiles_dir)
        ::OmnipackageAgent::Utils::Path.mkpath(config.lockfiles_dir, "#{key.gsub(/[^0-9a-z]/i, '_')}.lock")
      end
    end
  end
end
