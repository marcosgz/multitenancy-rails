# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "Multitenancy::VERSION" do
  it "is a string" do
    expect(Multitenancy::VERSION).to be_a(String)
  end

  it "matches semver format" do
    expect(Multitenancy::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end
end
