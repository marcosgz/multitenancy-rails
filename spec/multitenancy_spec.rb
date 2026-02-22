# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe Multitenancy do
  describe ".root" do
    it "returns a Pathname" do
      expect(Multitenancy.root).to be_a(Pathname)
    end
  end

  describe ".themes_root" do
    it "returns root joined with 'themes'" do
      expect(Multitenancy.themes_root).to eq(Multitenancy.root.join("themes"))
    end
  end

  describe ".themes" do
    it "discovers themes from subdirectories" do
      create_theme_dir("alpha")
      create_theme_dir("beta")

      expect(Multitenancy.themes.size).to eq(2)
      expect(Multitenancy.themes.map(&:name)).to contain_exactly("alpha", "beta")
    end

    it "ignores files in themes directory" do
      create_theme_dir("alpha")
      FileUtils.touch(Rails.root.join("themes", "not-a-theme.txt"))

      expect(Multitenancy.themes.size).to eq(1)
      expect(Multitenancy.themes.first.name).to eq("alpha")
    end

    it "memoizes the result" do
      create_theme_dir("alpha")

      first_call = Multitenancy.themes
      second_call = Multitenancy.themes
      expect(first_call).to equal(second_call)
    end

    it "returns empty array when themes directory has no subdirectories" do
      expect(Multitenancy.themes).to eq([])
    end
  end

  describe ".reset!" do
    it "clears memoized themes" do
      create_theme_dir("alpha")

      first_call = Multitenancy.themes
      Multitenancy.reset!
      second_call = Multitenancy.themes

      expect(first_call).not_to equal(second_call)
    end
  end

  describe ".config" do
    it "returns an OrderedOptions" do
      expect(Multitenancy.config).to be_a(ActiveSupport::OrderedOptions)
    end

    it "has default paths" do
      expect(Multitenancy.config.paths).to include("app/controllers", "app/models", "lib")
    end
  end

  describe "::Error" do
    it "is a subclass of StandardError" do
      expect(Multitenancy::Error).to be < StandardError
    end
  end
end
