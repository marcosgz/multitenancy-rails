# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Multitenancy::Integrations::Importmap do
  let(:app) { Rails.application }

  after do
    cleanup_theme_constants("alpha")
  end

  describe ".call" do
    it "skips when config.importmap is not available" do
      allow(app.config).to receive(:respond_to?).and_call_original
      allow(app.config).to receive(:respond_to?).with(:importmap).and_return(false)

      expect { described_class.call(app) }.not_to raise_error
    end

    context "with importmap available" do
      let(:theme_path) do
        create_theme_dir("alpha", subdirs: ["config", "app/javascript"])
      end

      before do
        # Create a valid importmap config file
        File.write(theme_path.join("config/importmap.rb"), "# theme importmap")

        # Add theme importmap path to app config so the integration can find it
        theme_importmap = theme_path.join("config/importmap.rb").to_s
        app.config.importmap.paths << theme_importmap unless app.config.importmap.paths.include?(theme_importmap)

        # Stub Importmap::Map if not already defined
        unless defined?(::Importmap::Map)
          stub_const("Importmap::Map", Class.new {
            def draw(path)
              # no-op for testing
            end
          })
        end
      end

      it "bootstraps themes first" do
        Multitenancy.themes.each { |t| t.bootstrap(app) }
        described_class.call(app)

        theme = Multitenancy.themes.first
        expect(theme.engine).to respond_to(:importmap)
      end

      it "creates importmap on each theme engine" do
        Multitenancy.themes.each { |t| t.bootstrap(app) }
        described_class.call(app)

        theme = Multitenancy.themes.first
        expect(theme.engine.importmap).to be_a(::Importmap::Map)
      end

      it "sets importmap_paths on each theme engine" do
        Multitenancy.themes.each { |t| t.bootstrap(app) }
        described_class.call(app)

        theme = Multitenancy.themes.first
        expect(theme.engine.importmap_paths).to eq([theme_path.join("config/importmap.rb").to_s])
      end

      it "sets importmap_cache_sweepers for themes with javascript dir" do
        Multitenancy.themes.each { |t| t.bootstrap(app) }
        described_class.call(app)

        theme = Multitenancy.themes.first
        expect(theme.engine.importmap_cache_sweepers).to include(theme_path.join("app/javascript").to_s)
      end

      it "removes theme importmap paths from app shared config" do
        Multitenancy.themes.each { |t| t.bootstrap(app) }

        # Add a theme path to the app's importmap paths
        theme_importmap = theme_path.join("config/importmap.rb").to_s
        app.config.importmap.paths << theme_importmap unless app.config.importmap.paths.include?(theme_importmap)

        described_class.call(app)

        remaining = app.config.importmap.paths.select { |p| p.to_s.start_with?(Rails.root.join("themes").to_s) }
        expect(remaining).to be_empty
      end

      context "development reloader" do
        it "adds reloader when cache_classes is false" do
          allow(app.config).to receive(:cache_classes).and_return(false)

          Multitenancy.reset!
          Multitenancy.themes.each { |t| t.bootstrap(app) }

          described_class.call(app)

          expect(app.reloaders).not_to be_empty
        end
      end
    end
  end
end
