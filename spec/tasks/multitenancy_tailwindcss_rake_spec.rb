# frozen_string_literal: true

require_relative "../spec_helper"
require "rake"

RSpec.describe "multitenancy:tailwindcss rake tasks" do
  before(:all) do
    Rake.application = Rake::Application.new
    Rake.application.rake_require("multitenancy_tailwindcss", [File.expand_path("../../lib/tasks", __dir__)])

    # Define a stub :environment task so the rake tasks can depend on it
    Rake::Task.define_task(:environment)
  end

  after(:all) do
    Rake.application = Rake::Application.new
  end

  before(:each) do
    # Re-enable tasks so they can be invoked again in each example
    Rake::Task["multitenancy:tailwindcss:build"].reenable
    Rake::Task["multitenancy:tailwindcss:watch"].reenable
  end

  describe "build" do
    it "prints message when no targets" do
      allow(Multitenancy::Integrations::TailwindCss).to receive(:compilation_targets).and_return([])

      expect {
        Rake::Task["multitenancy:tailwindcss:build"].invoke
      }.to output(/No multitenancy themes with Tailwind CSS found/).to_stdout
    end

    it "runs compile command per target" do
      target = {
        theme: double("theme", name: "alpha"),
        input: Pathname.new("/tmp/input.css"),
        output: Pathname.new("/tmp/output.css")
      }

      allow(Multitenancy::Integrations::TailwindCss).to receive(:compilation_targets).and_return([target])
      allow(Multitenancy::Integrations::TailwindCss).to receive(:compile_command).and_return(["echo", "ok"])

      expect {
        Rake::Task["multitenancy:tailwindcss:build"].invoke
      }.to output(/Building Tailwind CSS for theme 'alpha'/).to_stdout
    end
  end

  describe "watch" do
    it "prints message when no targets" do
      allow(Multitenancy::Integrations::TailwindCss).to receive(:compilation_targets).and_return([])

      expect {
        Rake::Task["multitenancy:tailwindcss:watch"].invoke
      }.to output(/No multitenancy themes with Tailwind CSS found/).to_stdout
    end
  end
end
