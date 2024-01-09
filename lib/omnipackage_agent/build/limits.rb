# frozen_string_literal: true

module OmnipackageAgent
  class Build
    class Limits
      class << self
        def deserialize(hash)
          return max unless hash

          new(memory: hash['memory'], cpus: hash['cpus'], pids: hash['pids'], execute_timeout: hash['execute_timeout'])
        end

        def max
          new(memory: '4000g', cpus: '4000', pids: 100_000, execute_timeout: 86_400)
        end
      end

      attr_reader :memory, :cpus, :execute_timeout, :pids

      def initialize(memory: nil, cpus: nil, pids: nil, execute_timeout: nil)
        @memory = memory || '4g'
        @cpus = cpus || '4'
        @execute_timeout = execute_timeout || 43_200
        @pids = pids || 10_000
      end

      def to_cli
        <<~CLI.chomp
          --memory=#{memory} --cpus="#{cpus}" --pids-limit=#{pids}
        CLI
      end
    end
  end
end
