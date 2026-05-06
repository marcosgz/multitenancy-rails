# frozen_string_literal: true

module Multitenancy
  module Integrations
    class ViewComponent
      def self.call(app)
        return unless defined?(::ViewComponent::Base)

        app.config.to_prepare do
          ActionController::Base.helper(Multitenancy::Components::Helper)
        end

        app.reloader.to_run do
          Multitenancy::Components::Resolver.clear_cache
        end
      end
    end
  end
end
