# frozen_string_literal: true

require "active_support/inflections"
require "rails/engine"

module Multitenancy
  class Theme
    attr_reader :path, :namespace, :engine

    def initialize(path:)
      @path = path
      @_bootstrapped = false
    end

    def bootstrap(app)
      return if @_bootstrapped

      @namespace = create_namespace
      @engine = create_engine
      inject_paths(app)

      @_bootstrapped = true
    end

    def relative_path
      path.relative_path_from(::Rails.root)
    end

    def mount_path
      "/#{name}"
    end

    def name
      path.basename.to_s.parameterize
    end

    private

    def create_namespace
      namespace_name = "themes/#{name}"
      namespace = ActiveSupport::Inflector.camelize(namespace_name)
      namespace.split("::").reduce(Object) do |base, mod|
        if base.const_defined?(mod, false)
          base.const_get(mod, false)
        else
          base.const_set(mod, Module.new)
        end
      end
    end

    def create_engine
      stim = Stim.new(self, namespace)
      namespace.const_set("Engine", Class.new(::Rails::Engine)).include(stim)
    end

    def inject_paths(app)
      Multitenancy.config.paths.each do |path|
        location = relative_path.join(path)

        next unless location.exist?
        next unless location.directory?

        app.autoloaders.main.push_dir(location.to_s, namespace: namespace)
      end

      js_path = self.path.join("app/javascript")
      app.config.assets.paths << js_path.to_s if js_path.exist?
    end
  end
end
