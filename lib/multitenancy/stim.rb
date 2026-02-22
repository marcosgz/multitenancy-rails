# frozen_string_literal: true

module Multitenancy
  class Stim < Module
    attr_reader :theme, :namespace

    def initialize(theme, namespace)
      @theme = theme
      @namespace = namespace
      super()
    end

    def included(engine)
      engine.called_from = theme.path
      engine.isolate_namespace(namespace)
      engine.config.root = theme.path

      views_path = theme.path.join("app/views")
      if views_path.exist?
        engine.paths["app/views"] = [views_path]
      end

      assets_path = theme.path.join("app/assets")
      if assets_path.exist?
        engine.paths["app/assets"] = [assets_path]
      end

      locale_path = theme.path.join("config/locales")
      if locale_path.exist?
        engine.paths["config/locales"] = [locale_path]
      end

      js_path = theme.path.join("app/javascript")
      if js_path.exist?
        engine.paths["app/javascript"] = [js_path]
      end
    end
  end
end
