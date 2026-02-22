# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/module/delegation"

module Multitenancy
  module Integrations

    class Importmap
      class Reloader < Struct.new(:app, :engine)
        delegate :execute_if_updated, :execute, :updated?, to: :updater

        def reload!
          engine.importmap = ::Importmap::Map.new
          app_importmap_paths.each { |path| engine.importmap.draw(path) }
          engine.importmap_paths.each { |path| engine.importmap.draw(path) }
        end

        private

        def updater
          @updater ||= app.config.file_watcher.new(engine.importmap_paths, cache_sweepers) { reload! }
        end

        def cache_sweepers
          engine.importmap_cache_sweepers.each_with_object({}) do |path, hash|
            hash[path] = ["js"]
          end
        end

        def app_importmap_paths
          app.config.importmap.paths
        end
      end

      def self.call(app)
        return unless app.config.respond_to?(:importmap)

        Multitenancy.themes.each do |theme|
          theme.engine.singleton_class.send(:attr_accessor, :importmap)
          theme.engine.singleton_class.send(:attr_accessor, :importmap_paths)
          theme.engine.singleton_class.send(:attr_accessor, :importmap_cache_sweepers)
          theme.engine.importmap = ::Importmap::Map.new

          # Store theme importmap paths separately — engine.config.importmap.paths
          # is a shared object across all railties, so we can't use it per-theme.
          importmap_file = theme.path.join("config/importmap.rb").to_s
          theme.engine.importmap_paths = [importmap_file]

          # Watch theme JavaScript directories for new/changed/deleted files
          js_path = theme.path.join("app/javascript")
          theme.engine.importmap_cache_sweepers = js_path.exist? ? [js_path.to_s] : []

          # Draw the main app's importmap first (Turbo, Stimulus, shared libs)
          app.config.importmap.paths.each { |path| theme.engine.importmap.draw(path) }

          # Then draw the theme's own importmap (can override app pins)
          theme.engine.importmap_paths.each { |path| theme.engine.importmap.draw(path) }

          # Development reloader: re-draw theme importmap when pins or JS change
          unless app.config.cache_classes
            Multitenancy::Integrations::Importmap::Reloader.new(app, theme.engine).tap do |reloader|
              app.reloaders << reloader
              app.reloader.to_run { reloader.execute_if_updated }
            end
          end
        end

        # Remove theme importmap paths from the main app's shared config
        # so the main app doesn't draw theme-specific pins into its own importmap.
        app.config.importmap.paths.delete_if do |path|
          path.to_s =~ %r{^#{Multitenancy.themes_root}/}
        end
      end
    end
  end
end
