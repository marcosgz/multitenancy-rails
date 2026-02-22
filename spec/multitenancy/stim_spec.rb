# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Multitenancy::Stim do
  let(:theme_path) { create_theme_dir("acme") }
  let(:theme) { Multitenancy::Theme.new(path: theme_path) }
  let(:namespace) { Module.new }
  let(:stim) { described_class.new(theme, namespace) }

  it "stores the theme" do
    expect(stim.theme).to eq(theme)
  end

  it "stores the namespace" do
    expect(stim.namespace).to eq(namespace)
  end

  describe "#included" do
    let(:engine_class) { Class.new(::Rails::Engine) }

    before do
      allow(engine_class).to receive(:called_from=)
      allow(engine_class).to receive(:isolate_namespace)
    end

    it "sets called_from to the theme path" do
      engine_class.include(stim)
      expect(engine_class).to have_received(:called_from=).with(theme_path)
    end

    it "calls isolate_namespace with the namespace" do
      engine_class.include(stim)
      expect(engine_class).to have_received(:isolate_namespace).with(namespace)
    end

    it "sets config.root to the theme path" do
      engine_class.include(stim)
      expect(engine_class.config.root).to eq(theme_path)
    end

    it "sets views path when directory exists" do
      FileUtils.mkdir_p(theme_path.join("app/views"))
      engine_class.include(stim)
      expect(engine_class.paths["app/views"].to_ary).to include(theme_path.join("app/views"))
    end

    it "sets assets path when directory exists" do
      FileUtils.mkdir_p(theme_path.join("app/assets"))
      engine_class.include(stim)
      expect(engine_class.paths["app/assets"].to_ary).to include(theme_path.join("app/assets"))
    end

    it "sets locales path when directory exists" do
      FileUtils.mkdir_p(theme_path.join("config/locales"))
      engine_class.include(stim)
      expect(engine_class.paths["config/locales"].to_ary).to include(theme_path.join("config/locales"))
    end

    it "sets javascript path when directory exists" do
      FileUtils.mkdir_p(theme_path.join("app/javascript"))
      engine_class.include(stim)
      expect(engine_class.paths["app/javascript"].to_ary).to include(theme_path.join("app/javascript"))
    end

    it "skips views path when directory does not exist" do
      original_paths = engine_class.paths["app/views"].to_ary.dup
      engine_class.include(stim)
      expect(engine_class.paths["app/views"].to_ary).to eq(original_paths)
    end
  end
end
