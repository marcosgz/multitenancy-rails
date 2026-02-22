# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Multitenancy::Theme do
  let(:theme_path) { create_theme_dir("acme") }
  let(:theme) { described_class.new(path: theme_path) }
  let(:app) { Rails.application }

  after do
    cleanup_theme_constants("acme")
  end

  describe "#name" do
    it "returns the parameterized basename" do
      expect(theme.name).to eq("acme")
    end

    it "parameterizes complex names" do
      path = create_theme_dir("My Cool Theme")
      t = described_class.new(path: path)
      expect(t.name).to eq("my-cool-theme")
    end
  end

  describe "#mount_path" do
    it "returns /name" do
      expect(theme.mount_path).to eq("/acme")
    end
  end

  describe "#relative_path" do
    it "returns path relative to Rails.root" do
      expect(theme.relative_path).to eq(Pathname.new("themes/acme"))
    end
  end

  describe "#bootstrap" do
    it "creates a namespace module" do
      theme.bootstrap(app)
      expect(theme.namespace).to eq(Themes::Acme)
    end

    it "creates an Engine class" do
      theme.bootstrap(app)
      expect(theme.engine).to be < ::Rails::Engine
    end

    it "is idempotent" do
      theme.bootstrap(app)
      first_namespace = theme.namespace
      first_engine = theme.engine

      theme.bootstrap(app)
      expect(theme.namespace).to equal(first_namespace)
      expect(theme.engine).to equal(first_engine)
    end

    it "pushes autoload dirs for existing paths" do
      FileUtils.mkdir_p(theme_path.join("app/controllers"))
      theme.bootstrap(app)
      expect(app.autoloaders.main).to have_received(:push_dir).at_least(:once)
    end

    it "adds JavaScript path to asset paths when dir exists" do
      FileUtils.mkdir_p(theme_path.join("app/javascript"))
      theme.bootstrap(app)
      expect(app.config.assets.paths).to include(theme_path.join("app/javascript").to_s)
    end

    it "skips missing directories" do
      theme.bootstrap(app)
      expect(app.config.assets.paths).not_to include(theme_path.join("app/javascript").to_s)
    end
  end
end
