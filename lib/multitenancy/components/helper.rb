# frozen_string_literal: true

module Multitenancy
  module Components
    module Helper
      def theme_component(name, **kwargs)
        Multitenancy::Components::Resolver
          .call(name, theme_name: Multitenancy::Components::Helper.theme_for(self))
          .new(**kwargs)
      end

      def self.theme_for(context)
        controller = context.respond_to?(:controller) ? context.controller : context
        return nil unless controller

        parent = controller.class.module_parent
        return nil if parent == Object
        return nil unless parent.name&.start_with?("Themes::")

        parent.name.sub(/^Themes::/, "").underscore
      end
    end
  end
end
