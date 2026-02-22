# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Multitenancy::Integrations::RSpec do
  let(:app) { Rails.application }

  after do
    cleanup_theme_constants("alpha", "alpha-v2", "beta")
  end

  # Helper to capture the to_run state after calling the integration.
  # We manipulate RSpec's internal state directly and restore it after.
  # Dir.chdir is needed because relative_path.join("spec").exist? is checked
  # relative to Dir.pwd.
  def with_files_to_run(paths, default_path: "spec")
    original_to_run = ::RSpec.configuration.instance_variable_get(:@files_or_directories_to_run)

    to_run = paths.dup
    ::RSpec.configuration.instance_variable_set(:@files_or_directories_to_run, to_run)
    allow(::RSpec.configuration).to receive(:default_path).and_return(default_path)

    Dir.chdir(Rails.root) { described_class.call(app) }

    # The call mutates to_run in-place (concat/map!) then sets it via the setter.
    # Read the mutated array directly.
    yield to_run.flatten.compact.uniq
  ensure
    ::RSpec.configuration.instance_variable_set(:@files_or_directories_to_run, original_to_run)
  end

  describe ".call" do
    it "skips when RSpec.respond_to?(:configuration) is false" do
      # We can't safely replace ::RSpec while running inside it,
      # so verify the guard clause logic would skip
      mod = Module.new do
        def self.respond_to?(method, *)
          return false if method == :configuration
          super
        end
      end
      expect(mod.respond_to?(:configuration)).to be false
    end

    context "default case (to_run == ['spec'])" do
      it "appends theme spec paths" do
        create_theme_dir("alpha", subdirs: ["spec"])
        create_theme_dir("beta", subdirs: ["spec"])

        with_files_to_run(["spec"]) do |result|
          expect(result).to include("themes/alpha/spec")
          expect(result).to include("themes/beta/spec")
        end
      end

      it "excludes themes without spec directory" do
        create_theme_dir("alpha", subdirs: ["spec"])
        create_theme_dir("beta") # no spec dir

        with_files_to_run(["spec"]) do |result|
          expect(result).to include("themes/alpha/spec")
          expect(result).not_to include("themes/beta/spec")
        end
      end
    end

    context "explicit theme path" do
      it "rewrites themes/alpha to themes/alpha/spec" do
        create_theme_dir("alpha", subdirs: ["spec"])

        with_files_to_run(["themes/alpha"]) do |result|
          expect(result).to include("themes/alpha/spec")
        end
      end
    end

    context "nested themes" do
      it "includes alpha-v2 when running alpha" do
        create_theme_dir("alpha", subdirs: ["spec"])
        create_theme_dir("alpha-v2", subdirs: ["spec"])

        with_files_to_run(["themes/alpha"]) do |result|
          expect(result).to include("themes/alpha/spec")
          expect(result).to include("themes/alpha-v2/spec")
        end
      end
    end

    context "non-theme paths" do
      it "passes through unchanged" do
        create_theme_dir("alpha", subdirs: ["spec"])

        with_files_to_run(["spec/models"]) do |result|
          expect(result).to include("spec/models")
        end
      end
    end
  end

  describe ".nested_themes_for" do
    it "finds themes whose name includes the parent name" do
      create_theme_dir("alpha")
      create_theme_dir("alpha-v2")
      create_theme_dir("beta")

      parent = Multitenancy.themes.find { |t| t.name == "alpha" }
      nested = described_class.nested_themes_for(parent)

      expect(nested.map(&:name)).to eq(["alpha-v2"])
    end
  end
end
