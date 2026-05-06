# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Multitenancy::Integrations::ViewComponent do
  let(:app) { Rails.application }

  describe ".call" do
    context "when ViewComponent::Base is not defined" do
      it "no-ops" do
        hide_const("ViewComponent::Base") if defined?(::ViewComponent::Base)
        expect(ActiveSupport).not_to receive(:on_load)

        expect { described_class.call(app) }.not_to raise_error
      end
    end

    context "when ViewComponent::Base is defined" do
      before do
        stub_const("ViewComponent::Base", Class.new) unless defined?(::ViewComponent::Base)
      end

      it "registers the helper on ActionController::Base" do
        captured_block = nil
        allow(ActiveSupport).to receive(:on_load).with(:action_controller_base) do |&blk|
          captured_block = blk
        end

        described_class.call(app)
        expect(captured_block).not_to be_nil

        receiver = Class.new
        expect(receiver).to receive(:helper).with(Multitenancy::Components::Helper)
        receiver.instance_exec(&captured_block)
      end
    end
  end
end
