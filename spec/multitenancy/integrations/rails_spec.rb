# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Multitenancy::Integrations::Rails do
  let(:app) { Rails.application }

  after do
    cleanup_theme_constants("alpha", "beta")
  end

  describe ".call" do
    it "calls bootstrap on each theme" do
      create_theme_dir("alpha")
      create_theme_dir("beta")

      themes = Multitenancy.themes
      themes.each { |t| allow(t).to receive(:bootstrap).and_call_original }

      described_class.call(app)

      themes.each do |theme|
        expect(theme).to have_received(:bootstrap).with(app)
      end
    end

    it "handles empty themes directory" do
      expect { described_class.call(app) }.not_to raise_error
    end
  end
end
