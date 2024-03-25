# frozen_string_literal: true

module OmnipackageAgent
  class Build
    class Secrets < ::Hash
      class << self
        def deserialize(hash)
          result = new
          return result unless hash

          hash.each do |k, v|
            result[k.to_s] = v.to_s
          end
          result
        end
      end

      def to_s
        inspect
      end

      def inspect
        "{#{keys.join(',')}}"
      end
    end
  end
end
