# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'json'

require 'omnipackage_agent/api/client/response'

module OmnipackageAgent
  module Api
    class Client
      def initialize(apihost, apikey)
        @apikey = apikey
        @uri = ::URI.parse(apihost)
        @uri = ::URI.join(@uri, 'agent_api') if @uri.path.empty?
        @sequence = 0
      end

      def call(payload)
        http = build_http
        request = build_request(payload)
        response = http.request(request)
        ::OmnipackageAgent::Api::Client::Response.new(code: response.code, payload: parse_json(response.body), headers: response.to_hash)
      rescue ::StandardError => e
        ::OmnipackageAgent::Api::Client::Response.new(code: response&.code, payload: parse_json(response&.body), exception: e, headers: response&.to_hash || {})
      end

      private

      attr_reader :uri, :apikey

      def build_request(payload)
        headers = {
          'Authorization' => "Bearer #{apikey}",
          'Content-Type'  => 'application/json',
          'Accept'        => 'application/json'
        }
        request = ::Net::HTTP::Post.new(uri, headers)
        request.body = ::JSON.dump({ payload: payload, sequence: @sequence += 1 })
        request
      end

      def build_http
        http = ::Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = 60
        http.ssl_timeout = 60
        http.read_timeout = 600
        http.write_timeout = 60
        http.set_debug_output($stdout) if @debug
        http.use_ssl = uri.scheme == 'https'
        http
      end

      def parse_json(body)
        ::JSON.parse(body)
      rescue ::StandardError
        {}
      end
    end
  end
end
