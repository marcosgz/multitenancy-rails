# frozen_string_literal: true

require "concurrent/map"

module Multitenancy
  module Components
    class Resolver
      CACHE = Concurrent::Map.new

      def self.call(name, theme_name:)
        CACHE.compute_if_absent([theme_name, name]) do
          themed = theme_name &&
            "Themes::#{theme_name.to_s.camelize}::#{name.to_s.camelize}Component".safe_constantize

          themed || "#{name.to_s.camelize}Component".constantize
        end
      end

      def self.clear_cache
        CACHE.clear
      end
    end
  end
end
