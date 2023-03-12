# frozen_string_literal: true

module Agent
  module Api
    class Client
      class Response
        attr_reader :ok, :payload, :headers, :exception

        def initialize(ok:, payload:, headers:, exception: nil) # rubocop: disable Naming/MethodParameterName
          @ok = ok
          @payload = payload
          @exception = exception
          @headers = headers.transform_keys(&:downcase)
          freeze
        end

        def next_poll_after
          res = headers['x-next-poll-after-seconds']&.first
          if res&.to_i&.positive?
            res.to_i
          else
            rand(19..29)
          end
        end

        def ok?
          ok == true
        end

        def error_message # rubocop: disable Metrics/AbcSize
          if ok?
            ''
          elsif payload['error'] && !exception
            payload['error']
          elsif exception && !payload['error']
            exception.message
          else
            "#{payload['error']} | #{exception&.message}"
          end
        end
      end
    end
  end
end
