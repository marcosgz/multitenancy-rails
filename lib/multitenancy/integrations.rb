require 'active_support'

module Multitenancy
  module Integrations
    autoload :FactoryBot, "multitenancy/integrations/factory_bot"
    autoload :Importmap, "multitenancy/integrations/importmap"
    autoload :Rails, "multitenancy/integrations/rails"
    autoload :TailwindCss, "multitenancy/integrations/tailwind_css"
    autoload :RSpec, "multitenancy/integrations/rspec"
  end
end
