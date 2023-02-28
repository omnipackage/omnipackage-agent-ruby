# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'json'

module Agent
  module Api
    class Client
      def initialize(apihost, apikey)
        @apikey = apikey
        @uri = ::URI.parse(apihost)
        @uri = ::URI.join(@uri, 'agent_api') if @uri.path.empty?
        freeze
      end

      def call(payload)
        http = build_http
        request = build_request(payload)
        response = http.request(request)
        ::JSON.parse(response.body) if response.body.present?
      end

      private

      attr_reader :uri, :apikey

      def build_request(payload)
        headers = {
          'X-APIKEY'      => apikey,
          'Content-Type'  => 'application/json',
          'Accept'        => 'application/json'
        }
        request = ::Net::HTTP::Post.new(uri, headers)
        request.body = ::JSON.dump(payload)
        request
      end

      def build_http
        http = ::Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = 10
        http.ssl_timeout = 10
        http.read_timeout = 30
        http.write_timeout = 30
        http.set_debug_output($stdout) if @debug
        http.use_ssl = uri.scheme == 'https'
        http
      end
    end
  end
end
