# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Multitenancy::Integrations::TailwindCss do
  let(:app) { Rails.application }

  after do
    cleanup_theme_constants("alpha")
  end

  describe ".call" do
    it "skips when Tailwindcss is not defined" do
      hide_const("Tailwindcss") if defined?(::Tailwindcss)
      expect { described_class.call(app) }.not_to raise_error
    end

    context "with Tailwindcss defined" do
      before do
        stub_const("Tailwindcss", Module.new) unless defined?(::Tailwindcss)
      end

      it "excludes tailwind dir from Propshaft" do
        theme_path = create_theme_dir("alpha", subdirs: ["app/assets/tailwind"])

        Multitenancy.themes.each { |t| t.bootstrap(app) }
        described_class.call(app)

        expect(app.config.assets.excluded_paths.map(&:to_s)).to include(
          theme_path.join("app/assets/tailwind").to_s
        )
      end

      it "creates builds directory" do
        theme_path = create_theme_dir("alpha", subdirs: ["app/assets/tailwind"])

        Multitenancy.themes.each { |t| t.bootstrap(app) }
        described_class.call(app)

        expect(theme_path.join("app/assets/builds/alpha")).to be_directory
      end

      it "skips themes without tailwind directory" do
        create_theme_dir("alpha")

        Multitenancy.themes.each { |t| t.bootstrap(app) }
        described_class.call(app)

        expect(app.config.assets.excluded_paths).to be_empty
      end
    end
  end

  describe ".compilation_targets" do
    it "returns empty when Tailwindcss is not defined" do
      hide_const("Tailwindcss") if defined?(::Tailwindcss)
      expect(described_class.compilation_targets).to eq([])
    end

    context "with Tailwindcss defined" do
      before do
        stub_const("Tailwindcss", Module.new) unless defined?(::Tailwindcss)
      end

      it "returns targets with correct input/output paths" do
        theme_path = create_theme_dir("alpha",
          subdirs: ["app/assets/tailwind/alpha", "app/assets/builds/alpha"])
        File.write(theme_path.join("app/assets/tailwind/alpha/application.css"), "@import 'tailwindcss';")

        Multitenancy.themes.each { |t| t.bootstrap(app) }

        targets = described_class.compilation_targets
        expect(targets.size).to eq(1)
        expect(targets.first[:input].to_s).to end_with("app/assets/tailwind/alpha/application.css")
        expect(targets.first[:output].to_s).to end_with("app/assets/builds/alpha/application.css")
        expect(targets.first[:theme].name).to eq("alpha")
      end

      it "returns empty when no input files exist" do
        create_theme_dir("alpha", subdirs: ["app/assets/tailwind/alpha"])
        # No application.css file created

        Multitenancy.themes.each { |t| t.bootstrap(app) }

        expect(described_class.compilation_targets).to eq([])
      end
    end
  end

  describe ".compile_command" do
    let(:executable) { "/usr/bin/tailwindcss" }

    before do
      stub_const("Tailwindcss::Ruby", double(executable: executable))
    end

    let(:target) do
      {
        input: Pathname.new("/themes/alpha/app/assets/tailwind/alpha/application.css"),
        output: Pathname.new("/themes/alpha/app/assets/builds/alpha/application.css")
      }
    end

    it "includes executable, --input, and --output" do
      cmd = described_class.compile_command(target)
      expect(cmd).to include(executable)
      expect(cmd).to include("--input")
      expect(cmd).to include("--output")
    end

    it "includes --minify by default" do
      cmd = described_class.compile_command(target)
      expect(cmd).to include("--minify")
    end

    it "omits --minify when debug: true" do
      cmd = described_class.compile_command(target, debug: true)
      expect(cmd).not_to include("--minify")
    end
  end

  describe ".watch_command" do
    let(:executable) { "/usr/bin/tailwindcss" }

    before do
      stub_const("Tailwindcss::Ruby", double(executable: executable))
    end

    let(:target) do
      {
        input: Pathname.new("/themes/alpha/app/assets/tailwind/alpha/application.css"),
        output: Pathname.new("/themes/alpha/app/assets/builds/alpha/application.css")
      }
    end

    it "appends --watch to compile command" do
      cmd = described_class.watch_command(target)
      expect(cmd.last).to eq("--watch")
    end
  end
end
