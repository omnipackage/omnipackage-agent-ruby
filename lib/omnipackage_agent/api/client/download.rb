# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'fileutils'

module OmnipackageAgent
  module Api
    class Client
      class Download
        def initialize(apikey)
          @apikey = apikey
          freeze
        end

        def download_decompress(uri, destination_path) # rubocop: disable Metrics/MethodLength
          uri = ::URI.parse(uri)

          request = ::Net::HTTP::Get.new(uri)
          build_http(uri).request(request) do |response|
            raise "download error: #{response}" if response.code != '200'

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

        def upload(uri, filepath, payload = {})
          uri = ::URI.parse(uri)
          headers = { 'Authorization' => "Bearer #{apikey}" }

          payload['data'] = ::File.open(filepath)
          request = ::Net::HTTP::Post.new(uri, headers)
          request.set_form(payload, 'multipart/form-data')
          build_http(uri, read_timeout: 10, write_timeout: 600).request(request) do |response|
            raise "upload error: #{response}" if response.code != '200'
          end
        end

        private

        attr_reader :apikey

        def build_http(uri, read_timeout: 1800, write_timeout: 120)
          http = ::Net::HTTP.new(uri.host, uri.port)
          http.open_timeout = 120
          http.ssl_timeout = 120
          http.read_timeout = read_timeout
          http.write_timeout = write_timeout
          http.set_debug_output($stdout) if @debug
          http.use_ssl = uri.scheme == 'https'
          http
        end
      end
    end
  end
end
