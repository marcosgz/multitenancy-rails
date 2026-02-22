# frozen_string_literal: true

require "active_support/inflections"

module Multitenancy
  module Integrations
    class Rails
      def self.call(app)
        Multitenancy.themes.each do |theme|
          theme.bootstrap(app)
        end
      end
    end
  end
end
