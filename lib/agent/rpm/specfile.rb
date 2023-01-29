# frozen_string_literal: true

require 'agent/utils/template'

module Agent
  module Rpm
    class Specfile < Agent::Utils::Template
      def name
        /[Nn]ame:(.+)/.match(template)[1].strip
      end
    end
  end
end
