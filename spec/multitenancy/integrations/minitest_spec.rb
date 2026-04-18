# frozen_string_literal: true

require_relative "../../spec_helper"
require "minitest"
require "rake/file_list"

RSpec.describe Multitenancy::Integrations::Minitest do
  let(:app) { Rails.application }

  after do
    cleanup_theme_constants("alpha", "alpha-v2", "beta")
    FileUtils.rm_rf(Rails.root.join("test")) if Rails.root.join("test").exist?
  end

  # Builds a fresh fake runner, applies the integration to it, then invokes
  # load_tests(argv) and returns the accumulated list of resolved test file paths.
  # Dir.chdir is needed because relative_path.join("test").exist? is checked against Dir.pwd.
  def with_tests_for(argv)
    loaded = []

    fake_runner = Class.new do
      class << self
        attr_accessor :_loaded

        def load_tests(argv)
          patterns = extract_filters(argv)
          list_tests(patterns).each { |path| _loaded << path }
        end

        private

        def extract_filters(argv)
          argv.filter_map do |path|
            path = path.tr("\\", "/")
            if Dir.exist?(path)
              "#{path}/**/*_test.rb"
            else
              path
            end
          end
        end

        def list_tests(patterns)
          if patterns.any?
            Rake::FileList[patterns]
          else
            Rake::FileList[default_test_glob].exclude(default_test_exclude_glob)
          end
        end

        def default_test_glob
          "test/**/*_test.rb"
        end

        def default_test_exclude_glob
          "test/{system,dummy,fixtures}/**/*_test.rb"
        end
      end
    end

    fake_runner._loaded = loaded

    stub_const("Rails::TestUnit::Runner", fake_runner)

    Dir.chdir(Rails.root) do
      described_class.call(app)
      fake_runner.load_tests(argv)
    end

    loaded
  end

  describe ".call" do
    context "guard clauses" do
      it "skips when Minitest is not defined" do
        hide_const("Minitest")
        expect { described_class.call(app) }.not_to raise_error
      end

      it "skips when Rails::TestUnit::Runner is not defined" do
        hide_const("Rails::TestUnit::Runner")
        expect { described_class.call(app) }.not_to raise_error
      end
    end

    context "default case (empty argv)" do
      it "includes theme test files when theme has a test/ directory" do
        create_theme_dir("alpha", subdirs: ["test"])
        FileUtils.touch(Rails.root.join("themes/alpha/test/alpha_test.rb"))

        result = with_tests_for([])
        expect(result).to include(match(%r{themes/alpha/test/alpha_test\.rb}))
      end

      it "excludes themes without a test/ directory" do
        create_theme_dir("alpha") # no test/ subdir

        result = with_tests_for([])
        expect(result).not_to include(match(%r{themes/alpha}))
      end

      it "includes test files from multiple themes" do
        create_theme_dir("alpha", subdirs: ["test"])
        create_theme_dir("beta", subdirs: ["test"])
        FileUtils.touch(Rails.root.join("themes/alpha/test/alpha_test.rb"))
        FileUtils.touch(Rails.root.join("themes/beta/test/beta_test.rb"))

        result = with_tests_for([])
        expect(result).to include(match(%r{themes/alpha/test/alpha_test\.rb}))
        expect(result).to include(match(%r{themes/beta/test/beta_test\.rb}))
      end
    end

    context "explicit theme path" do
      it "expands themes/alpha to themes/alpha/test" do
        create_theme_dir("alpha", subdirs: ["test"])
        FileUtils.touch(Rails.root.join("themes/alpha/test/alpha_test.rb"))

        result = with_tests_for(["themes/alpha"])
        expect(result).to include(match(%r{themes/alpha/test/alpha_test\.rb}))
      end

      it "omits theme when it has no test/ directory" do
        create_theme_dir("alpha") # no test/

        result = with_tests_for(["themes/alpha"])
        expect(result).to be_empty
      end
    end

    context "nested themes" do
      it "includes alpha-v2 tests when running themes/alpha" do
        create_theme_dir("alpha", subdirs: ["test"])
        create_theme_dir("alpha-v2", subdirs: ["test"])
        FileUtils.touch(Rails.root.join("themes/alpha/test/alpha_test.rb"))
        FileUtils.touch(Rails.root.join("themes/alpha-v2/test/alpha_v2_test.rb"))

        result = with_tests_for(["themes/alpha"])
        expect(result).to include(match(%r{themes/alpha/test/alpha_test\.rb}))
        expect(result).to include(match(%r{themes/alpha-v2/test/alpha_v2_test\.rb}))
      end

      it "does not include beta tests when running themes/alpha" do
        create_theme_dir("alpha", subdirs: ["test"])
        create_theme_dir("beta", subdirs: ["test"])
        FileUtils.touch(Rails.root.join("themes/alpha/test/alpha_test.rb"))
        FileUtils.touch(Rails.root.join("themes/beta/test/beta_test.rb"))

        result = with_tests_for(["themes/alpha"])
        expect(result).not_to include(match(%r{themes/beta}))
      end
    end

    context "non-theme paths" do
      it "passes through non-theme paths unchanged" do
        FileUtils.mkdir_p(Rails.root.join("test/models"))
        FileUtils.touch(Rails.root.join("test/models/user_test.rb"))

        result = with_tests_for(["test/models"])
        expect(result).to include(match(%r{test/models/user_test\.rb}))
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

    it "excludes the parent theme itself" do
      create_theme_dir("alpha")
      create_theme_dir("alpha-v2")

      parent = Multitenancy.themes.find { |t| t.name == "alpha" }
      nested = described_class.nested_themes_for(parent)

      expect(nested.map(&:name)).not_to include("alpha")
    end
  end
end
