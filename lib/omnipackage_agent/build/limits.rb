# frozen_string_literal: true

module OmnipackageAgent
  class Build
    class Limits
      class << self
        def deserialize(hash)
          return new unless hash

          new(memory: hash['memory'], cpus: hash['cpus'], pids: hash['pids'], execute_timeout: hash['execute_timeout'])
        end
      end

      attr_reader :memory, :cpus, :execute_timeout, :pids

      def initialize(memory: nil, cpus: nil, pids: nil, execute_timeout: nil)
        @memory = memory || memtotal
        @cpus = cpus || nproc
        @execute_timeout = execute_timeout || 86_400
        @pids = pids || pid_max
      end

      def to_cli
        <<~CLI.chomp
          --memory="#{memory}" --cpus="#{cpus}" --pids-limit="#{pids}"
        CLI
      end

      private

      def nproc
        [`nproc`.chomp.to_i - 1, 1].max.to_s
      rescue ::StandardError
        '1024'
      end

      def memtotal
        (`grep MemTotal /proc/meminfo`.chomp.gsub(/\D/, '').to_i * 0.86).round.to_s + 'k' # rubocop: disable Style/StringConcatenation
      rescue ::StandardError
        '4096g'
      end

      def pid_max
        (`cat /proc/sys/kernel/pid_max`.chomp.to_i * 0.86).round.to_s
      rescue ::StandardError
        '10000'
      end
    end
  end
end
