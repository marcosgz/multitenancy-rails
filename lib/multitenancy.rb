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
      current_paths = themes_root.exist? ? themes_root.children.select(&:directory?).sort : []
      keys = current_paths.map(&:to_s)

      return @themes if @themes_keys == keys

      @themes_cache ||= {}
      current_paths.each { |path| @themes_cache[path.to_s] ||= Multitenancy::Theme.new(path: path) }
      @themes_cache.delete_if { |key, _| !keys.include?(key) }

      @themes_keys = keys
      @themes = keys.map { |key| @themes_cache[key] }
    end

    def reset!
      @themes = nil
      @themes_keys = nil
      @themes_cache = nil
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
    app/presenters
    app/decorators
    app/queries
    app/resources
    app/serializers
    app/transformers
    app/validators
    app/workers
    app/jobs
    app/mailers
    app/notifications
    app/policies
    lib
  ]

  require "multitenancy/railtie"
end
