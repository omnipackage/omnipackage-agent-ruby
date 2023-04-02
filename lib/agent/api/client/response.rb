# frozen_string_literal: true

module Agent
  module Api
    class Client
      class Response
        attr_reader :code, :payload, :headers, :exception

        def initialize(code:, payload:, headers:, exception: nil)
          @code = code
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
          code == '200'
        end

        def error_message # rubocop: disable Metrics/AbcSize
          return '' if ok?

          text = if payload['error'] && !exception
                   payload['error']
                 elsif exception && !payload['error']
                   exception.message
                 else
                   "#{payload['error']} | #{exception&.message}"
                 end

          "[#{code}] #{text}"
        end
      end
    end
  end
end
