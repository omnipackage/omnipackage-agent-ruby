# frozen_string_literal: true

require 'omnipackage_agent/utils/template'

module OmnipackageAgent
  module Build
    module Rpm
      class Specfile < ::OmnipackageAgent::Utils::Template
        def name
          /[Nn]ame:(.+)/.match(template)[1].strip
        end
      end
    end
  end
end
