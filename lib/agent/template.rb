# frozen_string_literal: true

require 'erb'
require 'ostruct'

module Agent
  class Template
    def initialize(hash)
      @h = hash
    end

    def render(erb_template)
      ERB.new(erb_template).result(binding)
    end

    def method_missing(method_name, *arguments, &block)
      if h.key?(method_name.to_s)
        h.fetch(method_name.to_s)
      elsif h.key?(method_name.to_sym)
        h.fetch(method_name.to_sym)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      h.key?(method_name.to_s) || h.key?(method_name.to_sym) || super
    end

    private

    attr_reader :h
  end
end
