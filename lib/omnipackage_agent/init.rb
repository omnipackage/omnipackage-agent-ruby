# frozen_string_literal: true

require 'pathname'

module OmnipackageAgent
  class Init
    attr_reader :path, :config

    def initialize(path:, config:)
      @path = ::Pathname.new(path)
      @config = config
    end

    def call
    end
  end
end
