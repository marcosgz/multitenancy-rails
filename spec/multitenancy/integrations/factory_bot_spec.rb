# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Multitenancy::Integrations::FactoryBot do
  let(:app) { Rails.application }

  after do
    cleanup_theme_constants("alpha")
  end

  describe ".call" do
    it "skips when config.factory_bot is not available" do
      allow(app.config).to receive(:respond_to?).and_call_original
      allow(app.config).to receive(:respond_to?).with(:factory_bot).and_return(false)

      create_theme_dir("alpha")

      expect { described_class.call(app) }.not_to raise_error
    end

    it "appends theme spec/factories paths when factory_bot is available" do
      create_theme_dir("alpha", subdirs: ["spec/factories"])

      described_class.call(app)

      paths = app.config.factory_bot.definition_file_paths
      expect(paths).to include("themes/alpha/spec/factories")
    end
  end
end
