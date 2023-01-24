# frozen_string_literal: true

require 'erb'
require 'ostruct'

module Agent
  class Template < OpenStruct
    def render(erb_template)
      ERB.new(erb_template).result(binding)
    end
  end
end
