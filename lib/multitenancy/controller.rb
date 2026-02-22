# frozen_string_literal: true

require "active_support/concern"

module Multitenancy
  module Controller
    extend ActiveSupport::Concern

    included do
      engine = module_parent::Engine
      prepend_view_path engine.root.join("app/views")
      layout "application"
    end

    private

    def _prefixes
      namespace_prefix = "#{self.class.module_parent.name.underscore}/"
      super.map do |prefix|
        prefix.sub(/^#{Regexp.escape(namespace_prefix)}/, "")
      end.reject(&:empty?)
    end
  end
end
