# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Multitenancy::Controller do
  let(:theme_path) { create_theme_dir("acme", subdirs: ["app/views"]) }
  let(:app) { Rails.application }

  after do
    cleanup_theme_constants("acme")
  end

  let(:controller_class) do
    theme = Multitenancy::Theme.new(path: theme_path)
    theme.bootstrap(app)
    ns = theme.namespace

    # Build a controller class inside the theme namespace
    klass = Class.new(ActionController::Base)
    ns.const_set(:ApplicationController, klass)
    klass.include(Multitenancy::Controller)
    klass
  end

  describe "included block" do
    it "prepends engine view path" do
      view_paths = controller_class.view_paths.map(&:to_s)
      expect(view_paths.first).to include("acme/app/views")
    end

    it "sets layout to application" do
      # Rails stores layout as a proc or string; verify via _layout
      instance = controller_class.new
      # The layout method should resolve to "application"
      expect(controller_class._layout).to eq("application")
    end
  end

  describe "#_prefixes" do
    it "strips namespace prefix from prefixes" do
      instance = controller_class.new
      prefixes = instance.send(:_prefixes)
      prefixes.each do |prefix|
        expect(prefix).not_to start_with("themes/acme/")
      end
    end

    it "rejects empty prefixes" do
      instance = controller_class.new
      prefixes = instance.send(:_prefixes)
      expect(prefixes).not_to include("")
    end
  end
end
