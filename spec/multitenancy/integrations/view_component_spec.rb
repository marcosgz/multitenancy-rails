# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Multitenancy::Integrations::ViewComponent do
  let(:app) { Rails.application }

  describe ".call" do
    context "when ViewComponent::Base is not defined" do
      it "no-ops" do
        hide_const("ViewComponent::Base") if defined?(::ViewComponent::Base)
        expect(app.config).not_to receive(:to_prepare)
        expect(app.reloader).not_to receive(:to_run)

        expect { described_class.call(app) }.not_to raise_error
      end
    end

    context "when ViewComponent::Base is defined" do
      before do
        stub_const("ViewComponent::Base", Class.new) unless defined?(::ViewComponent::Base)
      end

      it "registers a to_prepare callback that adds the helper to ActionController::Base" do
        prepare_block = nil
        allow(app.config).to receive(:to_prepare) { |&blk| prepare_block = blk }
        allow(app.reloader).to receive(:to_run)

        described_class.call(app)
        expect(prepare_block).not_to be_nil

        expect(ActionController::Base).to receive(:helper).with(Multitenancy::Components::Helper)
        prepare_block.call
      end

      it "registers a reloader callback that clears the resolver cache" do
        allow(app.config).to receive(:to_prepare)
        reloader_block = nil
        allow(app.reloader).to receive(:to_run) { |&blk| reloader_block = blk }

        described_class.call(app)
        expect(reloader_block).not_to be_nil

        expect(Multitenancy::Components::Resolver).to receive(:clear_cache)
        reloader_block.call
      end
    end
  end
end
