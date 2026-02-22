# frozen_string_literal: true

require_relative "boot"

require "action_controller/railtie"
require "action_view/railtie"
require "propshaft"
require "importmap-rails"
require "factory_bot_rails"
require "multitenancy"

module Dummy
  class Application < Rails::Application
    config.eager_load = false
    config.root = File.expand_path("..", __dir__)
  end
end
