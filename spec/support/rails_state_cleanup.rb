# frozen_string_literal: true

module RailsStateCleanup
  def snapshot_rails_state
    app = Rails.application
    @_snapshot = {}
    @_snapshot[:asset_paths] = app.config.assets.paths.dup
    @_snapshot[:asset_excluded_paths] = app.config.assets.excluded_paths.dup

    if app.config.respond_to?(:importmap)
      @_snapshot[:importmap_paths] = app.config.importmap.paths.dup
    end

    if app.config.respond_to?(:factory_bot)
      @_snapshot[:factory_bot_paths] = app.config.factory_bot.definition_file_paths.dup
    end

    @_snapshot[:reloaders] = app.reloaders.dup
  end

  def restore_rails_state
    return unless @_snapshot

    app = Rails.application
    app.config.assets.paths.replace(@_snapshot[:asset_paths])
    app.config.assets.excluded_paths.replace(@_snapshot[:asset_excluded_paths])

    if @_snapshot.key?(:importmap_paths)
      app.config.importmap.paths.replace(@_snapshot[:importmap_paths])
    end

    if @_snapshot.key?(:factory_bot_paths)
      app.config.factory_bot.definition_file_paths.replace(@_snapshot[:factory_bot_paths])
    end

    app.reloaders.replace(@_snapshot[:reloaders])
  end
end
