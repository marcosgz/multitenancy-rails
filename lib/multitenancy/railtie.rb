require "rails/railtie"

module Multitenancy
  class Railtie < ::Rails::Railtie
    config.before_configuration do |app|
      Integrations::Rails.call(app)
      Integrations::FactoryBot.call(app)
      Integrations::RSpec.call(app)
      Integrations::Minitest.call(app)

      # Must run before Propshaft's `propshaft.append_assets_path` initializer,
      # which is where `config.assets.excluded_paths` is consumed
      # (`paths.without(excluded_paths)`). Registering the exclusion any later —
      # e.g. in `after_initialize` — leaves the raw Tailwind input directory on
      # the asset load path, where it collides with the compiled `builds/`
      # output and can be served as un-compiled `@import "tailwindcss"` source.
      Integrations::TailwindCss.call(app)

      # This is not used within multitenancy. Rather, this allows OTHER tools to
      # hook into multitenancy via ActiveSupport hooks.
      ActiveSupport.run_load_hooks(:multitenancy, Multitenancy)
    end

    config.after_initialize do |app|
      Integrations::Importmap.call(app)
    end

    rake_tasks do
      load "tasks/multitenancy_tailwindcss.rake"
    end
  end
end
