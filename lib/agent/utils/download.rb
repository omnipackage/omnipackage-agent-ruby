# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'fileutils'

module Agent
  module Utils
    module Download
      extend self

      def download_decompress(uri, destination_path, headers: {}) # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
        http = ::Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = 10
        http.ssl_timeout = 10
        http.read_timeout = 600
        http.write_timeout = 10
        # http.set_debug_output($stdout) if @debug
        http.use_ssl = uri.scheme == 'https'

        request = ::Net::HTTP::Get.new(uri, headers)
        http.request(request) do |response|
          raise "download error #{response}" if response.code != '200'
          #cd = response.to_hash['content-disposition']&.first || (raise 'no content-disposition')
          #filename = cd.match(/filename=(\"?)(.+)\1/)[2] # rubocop: disable Style/RedundantRegexpEscape

          ::FileUtils.mkdir_p(destination_path)
          first_stdin, wait_threads = ::Open3.pipeline_w(
            [{}, 'tar', '--directory', destination_path, '-xJf', '-']
          )
          first_stdin.binmode
          response.read_body do |data|
            first_stdin.write(data)
          end
          first_stdin.close
          wait_threads.each(&:join)
          return destination_path
          #f = ::File.open(::File.join(destination_path, filename), 'wb')
          #response.read_body do |data|
          #  f.write(data)
          #end
          #f.close
          #return f.path
        end
      end
    end
  end
end
