# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Multitenancy::Components::Resolver do
  before { described_class.clear_cache }
  after { described_class.clear_cache }

  def define_theme_component(theme, name, value = Class.new)
    Object.const_set(:Themes, Module.new) unless defined?(::Themes)
    ::Themes.const_set(theme, Module.new) unless ::Themes.const_defined?(theme, false)
    ::Themes.const_get(theme).const_set(name, value)
    value
  end

  describe ".call" do
    context "with a theme_name and matching override" do
      let!(:override) { define_theme_component(:Community, :StoryCardComponent) }

      before { stub_const("StoryCardComponent", Class.new) }

      it "returns the themed override" do
        expect(described_class.call(:story_card, theme_name: "community"))
          .to eq(override)
      end

      it "accepts a symbol theme_name" do
        expect(described_class.call(:story_card, theme_name: :community))
          .to eq(override)
      end
    end

    context "without a matching override" do
      before { stub_const("StoryCardComponent", Class.new) }

      it "falls back to the shared component when override is undefined" do
        expect(described_class.call(:story_card, theme_name: "community"))
          .to eq(StoryCardComponent)
      end

      it "returns the shared component when theme_name is nil" do
        expect(described_class.call(:story_card, theme_name: nil))
          .to eq(StoryCardComponent)
      end
    end

    context "with no shared component defined" do
      it "raises NameError" do
        expect { described_class.call(:nonexistent, theme_name: nil) }
          .to raise_error(NameError)
      end
    end

    context "caching" do
      before { stub_const("StoryCardComponent", Class.new) }

      it "caches resolution by [theme_name, name]" do
        described_class.call(:story_card, theme_name: nil)
        expect(described_class::CACHE.keys).to include([nil, :story_card])
      end

      it "stores distinct entries per theme_name" do
        define_theme_component(:Community, :StoryCardComponent)

        described_class.call(:story_card, theme_name: nil)
        described_class.call(:story_card, theme_name: "community")

        expect(described_class::CACHE.keys)
          .to include([nil, :story_card], ["community", :story_card])
      end
    end
  end

  describe ".clear_cache" do
    it "empties the cache" do
      stub_const("StoryCardComponent", Class.new)
      described_class.call(:story_card, theme_name: nil)
      expect(described_class::CACHE).not_to be_empty

      described_class.clear_cache
      expect(described_class::CACHE).to be_empty
    end
  end
end
