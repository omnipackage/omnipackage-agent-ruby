# frozen_string_literal: true

module Agent
  class TimedQueue
    def initialize
      @q = ::Queue.new
      @sema = ::Mutex.new
    end

    def push(data)
      sema.synchronize do
        q.push(data)
      end
      data
    end

    def pop(timeout_sec) # rubocop: disable Metrics/MethodLength
      sema.synchronize do
        begin_time = mtime
        begin
          q.pop(true)
        rescue ::ThreadError => _e
          if mtime - begin_time > timeout_sec # rubocop: disable Style/GuardClause
            return
          else
            sleep(0.01)
            retry
          end
        end
      end
    end

    private

    attr_reader :q, :sema

    def mtime
      ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
    end
  end
end
