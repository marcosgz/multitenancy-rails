# frozen_string_literal: true

require "active_support"
require "rails/application"

module Multitenancy
  extend ActiveSupport::Autoload

  autoload :Controller
  autoload :Integrations
  autoload :Railtie
  autoload :Stim
  autoload :Theme

  class Error < StandardError; end

  class << self
    attr_reader :config

    def root
      @root ||= ::Rails::Application.find_root(Dir.pwd)
    end

    def themes_root
      root.join("themes")
    end

    def themes
      @themes ||= themes_root.children.select(&:directory?).map do |theme|
        Multitenancy::Theme.new(path: theme)
      end
    end

    def reset!
      @themes = nil
    end
  end

  @config = ActiveSupport::OrderedOptions.new
  @config.paths = %w[
    app/controllers
    app/channels
    app/helpers
    app/services
    app/structs
    app/models
    app/mailers
    lib
  ]

  require "multitenancy/railtie"
end
