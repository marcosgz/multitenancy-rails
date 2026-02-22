# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "dummy/config/environment"

require "multitenancy"
require "multitenancy/theme"
require "multitenancy/stim"
require "multitenancy/controller"
require "multitenancy/integrations"
require "multitenancy/integrations/rails"
require "multitenancy/integrations/factory_bot"
require "multitenancy/integrations/rspec"
require "multitenancy/integrations/importmap"
require "multitenancy/integrations/tailwind_css"

Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FakeThemeHelpers
  config.include RailsStateCleanup

  # Run every example with Dir.pwd set to the dummy app root so that
  # relative paths (e.g. theme.relative_path.join("spec").exist?) resolve
  # against the correct directory tree.
  config.around(:each) do |example|
    Dir.chdir(Rails.root) { example.run }
  end

  config.before(:each) do
    snapshot_rails_state
    # Point Multitenancy.root at the dummy app (not the host project)
    Multitenancy.instance_variable_set(:@root, Rails.root)
    Multitenancy.reset!
    allow(Rails.application.autoloaders.main).to receive(:push_dir)
  end

  config.after(:each) do
    cleanup_dummy_themes
    restore_rails_state
    # Remove every theme constant created during the example
    if defined?(Themes)
      Themes.constants.each { |c| Themes.send(:remove_const, c) }
      Object.send(:remove_const, :Themes)
    end
  end
end
