# frozen_string_literal: true

require_relative "../spec_helper"
require "generators/multitenancy/multitenancy_generator"
require "tmpdir"
require "fileutils"

RSpec.describe Multitenancy::MultitenancyGenerator do
  let(:tmpdir) { Pathname.new(Dir.mktmpdir("generator-test-")) }

  after { FileUtils.rm_rf(tmpdir) }

  def run_generator(args)
    described_class.start(args, destination_root: tmpdir)
  end

  describe "default options" do
    before { run_generator(["my_theme"]) }

    it "creates controllers" do
      expect(tmpdir.join("themes/my_theme/app/controllers/application_controller.rb")).to exist
      expect(tmpdir.join("themes/my_theme/app/controllers/home_controller.rb")).to exist
    end

    it "creates views" do
      expect(tmpdir.join("themes/my_theme/app/views/layouts/application.html.erb")).to exist
      expect(tmpdir.join("themes/my_theme/app/views/home/index.html.erb")).to exist
    end

    it "creates stylesheets directory" do
      expect(tmpdir.join("themes/my_theme/app/assets/stylesheets/my_theme")).to be_directory
    end

    it "creates importmap config" do
      expect(tmpdir.join("themes/my_theme/config/importmap.rb")).to exist
    end

    it "creates JavaScript directories" do
      expect(tmpdir.join("themes/my_theme/app/javascript/my_theme")).to be_directory
      expect(tmpdir.join("themes/my_theme/app/javascript/my_theme/controllers")).to be_directory
    end

    it "creates JavaScript files" do
      expect(tmpdir.join("themes/my_theme/app/javascript/my_theme/application.js")).to exist
      expect(tmpdir.join("themes/my_theme/app/javascript/my_theme/controllers/hello_controller.js")).to exist
    end

    it "creates routes file" do
      expect(tmpdir.join("themes/my_theme/config/routes.rb")).to exist
    end

    it "creates locale file" do
      expect(tmpdir.join("themes/my_theme/config/locales/en.yml")).to exist
    end

    it "includes importmap tags in layout" do
      layout = tmpdir.join("themes/my_theme/app/views/layouts/application.html.erb").read
      expect(layout).to include("javascript_importmap_tags")
    end
  end

  describe "--tailwindcss" do
    before { run_generator(["my_theme", "--tailwindcss"]) }

    it "creates tailwind directory instead of stylesheets" do
      expect(tmpdir.join("themes/my_theme/app/assets/tailwind/my_theme")).to be_directory
      expect(tmpdir.join("themes/my_theme/app/assets/stylesheets/my_theme")).not_to exist
    end

    it "creates builds directory" do
      expect(tmpdir.join("themes/my_theme/app/assets/builds/my_theme")).to be_directory
    end

    it "generates @import template" do
      css = tmpdir.join("themes/my_theme/app/assets/tailwind/my_theme/application.css").read
      expect(css).to include("@import")
    end
  end

  describe "--no-importmap" do
    before { run_generator(["my_theme", "--no-importmap"]) }

    it "skips JavaScript directories" do
      expect(tmpdir.join("themes/my_theme/app/javascript")).not_to exist
    end

    it "skips importmap config" do
      expect(tmpdir.join("themes/my_theme/config/importmap.rb")).not_to exist
    end

    it "layout does not have importmap tags" do
      layout = tmpdir.join("themes/my_theme/app/views/layouts/application.html.erb").read
      expect(layout).not_to include("javascript_importmap_tags")
    end
  end

  describe "theme name parameterization" do
    before { run_generator(["My Cool Theme"]) }

    it "creates directory with parameterized name" do
      expect(tmpdir.join("themes/my-cool-theme")).to be_directory
    end

    it "uses parameterized name in controller namespace" do
      content = tmpdir.join("themes/my-cool-theme/app/controllers/application_controller.rb").read
      expect(content).to include("Themes::")
      expect(content).to include("ApplicationController")
    end
  end
end
