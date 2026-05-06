# frozen_string_literal: true

module Multitenancy
  module Integrations
    class ViewComponent
      def self.call(app)
        return unless defined?(::ViewComponent::Base)

        ActiveSupport.on_load(:action_controller_base) do
          helper Multitenancy::Components::Helper
        end
      end
    end
  end
end
