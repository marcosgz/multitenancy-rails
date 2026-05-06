# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Multitenancy::Components::Helper do
  def define_theme_const(theme, name, value = Class.new)
    Object.const_set(:Themes, Module.new) unless defined?(::Themes)
    ::Themes.const_set(theme, Module.new) unless ::Themes.const_defined?(theme, false)
    ::Themes.const_get(theme).const_set(name, value)
    value
  end

  describe ".theme_for" do
    it "returns the underscored theme name for a controller in a Themes:: namespace" do
      controller_class = define_theme_const(:Community, :HomeController)
      expect(described_class.theme_for(controller_class.new)).to eq("community")
    end

    it "underscores multi-word camelcased theme names" do
      controller_class = define_theme_const(:MyStore, :HomeController)
      expect(described_class.theme_for(controller_class.new)).to eq("my_store")
    end

    it "returns nil for a top-level (main-app) controller" do
      stub_const("MainAppController", Class.new)
      expect(described_class.theme_for(MainAppController.new)).to be_nil
    end

    it "returns nil for a controller in a non-Themes namespace" do
      stub_const("Admin", Module.new)
      stub_const("Admin::DashboardController", Class.new)

      expect(described_class.theme_for(Admin::DashboardController.new)).to be_nil
    end

    it "reads from .controller when the context is a view-like object" do
      controller_class = define_theme_const(:Community, :HomeController)
      controller = controller_class.new
      view_context = Object.new
      view_context.define_singleton_method(:controller) { controller }

      expect(described_class.theme_for(view_context)).to eq("community")
    end

    it "returns nil when the context exposes a nil controller" do
      view_context = Object.new
      view_context.define_singleton_method(:controller) { nil }

      expect(described_class.theme_for(view_context)).to be_nil
    end
  end

  describe "#theme_component" do
    let(:context) do
      Class.new do
        include Multitenancy::Components::Helper
      end.new
    end

    before do
      stub_const("StoryCardComponent", Class.new {
        def initialize(**kwargs)
          @kwargs = kwargs
        end
        attr_reader :kwargs
      })
      Multitenancy::Components::Resolver.clear_cache
    end

    after { Multitenancy::Components::Resolver.clear_cache }

    it "instantiates the resolved component with the given kwargs" do
      component = context.theme_component(:story_card, title: "Hello")
      expect(component).to be_a(StoryCardComponent)
      expect(component.kwargs).to eq(title: "Hello")
    end
  end
end
