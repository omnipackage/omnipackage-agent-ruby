# frozen_string_literal: true

module OmnipackageAgent
  class TimedQueue
    def initialize
      @q = ::Queue.new
    end

    def push(data)
      q.push(data)
      data
    end

    def pop(timeout_sec)
      begin_time = mtime
      begin
        q.pop(true)
      rescue ::ThreadError => _e
        if mtime - begin_time <= timeout_sec
          sleep(0.01)
          retry
        end
      end
    end

    private

    attr_reader :q

    def mtime
      ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
    end
  end
end
