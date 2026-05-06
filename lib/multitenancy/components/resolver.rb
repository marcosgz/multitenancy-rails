# frozen_string_literal: true

module Multitenancy
  module Components
    class Resolver
      def self.call(name, theme_name:)
        themed = theme_name &&
          "Themes::#{theme_name.to_s.camelize}::#{name.to_s.camelize}Component".safe_constantize

        themed || "#{name.to_s.camelize}Component".constantize
      end
    end
  end
end
