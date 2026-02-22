require "rails/railtie"

module Multitenancy
  class Railtie < ::Rails::Railtie
    config.before_configuration do |app|
      Integrations::Rails.call(app)
      Integrations::FactoryBot.call(app)
      Integrations::RSpec.call(app)

      # This is not used within multitenancy. Rather, this allows OTHER tools to
      # hook into multitenancy via ActiveSupport hooks.
      ActiveSupport.run_load_hooks(:multitenancy, Multitenancy)
    end

    config.after_initialize do |app|
      Integrations::Importmap.call(app)
      Integrations::TailwindCss.call(app)
    end

    rake_tasks do
      load "tasks/multitenancy_tailwindcss.rake"
    end
  end
end
