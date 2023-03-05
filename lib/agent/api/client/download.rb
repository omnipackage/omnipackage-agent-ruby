# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'fileutils'

module Agent
  module Api
    class Client
      class Download
        def initialize(apikey)
          @headers = { 'X-APIKEY' => apikey }.freeze
          freeze
        end

        def download_decompress(uri, destination_path) # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
          uri = ::URI.parse(uri)

          request = ::Net::HTTP::Get.new(uri, headers)
          build_http(uri).request(request) do |response|
            raise "download error #{response}" if response.code != '200'

            first_stdin, wait_threads = ::Open3.pipeline_w(
              [{}, 'tar', '--directory', destination_path, '-xJf', '-']
            )
            first_stdin.binmode
            response.read_body do |data|
              first_stdin.write(data)
            end
            first_stdin.close
            wait_threads.each(&:join)
          end

          destination_path
        end

        private

        attr_reader :headers

        def build_http(uri)
          http = ::Net::HTTP.new(uri.host, uri.port)
          http.open_timeout = 10
          http.ssl_timeout = 10
          http.read_timeout = 600
          http.write_timeout = 10
          http.set_debug_output($stdout) if @debug
          http.use_ssl = uri.scheme == 'https'
          http
        end
      end
    end
  end
end
