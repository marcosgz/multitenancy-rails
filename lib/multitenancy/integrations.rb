require 'active_support'

module Multitenancy
  module Integrations
    autoload :FactoryBot, "multitenancy/integrations/factory_bot"
    autoload :Importmap, "multitenancy/integrations/importmap"
    autoload :Rails, "multitenancy/integrations/rails"
    autoload :TailwindCss, "multitenancy/integrations/tailwind_css"
    autoload :Minitest, "multitenancy/integrations/minitest"
    autoload :RSpec, "multitenancy/integrations/rspec"
    autoload :ViewComponent, "multitenancy/integrations/view_component"
  end
end
