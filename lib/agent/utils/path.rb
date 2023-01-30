# frozen_string_literal: true

require 'pathname'

module Agent
  module Utils
    module Path
      extend self

      def mkpath(*parts)
        Pathname.new(parts[0]).join(*parts[1..-1])
      end
    end
  end
end
