# frozen_string_literal: true

require "fileutils"
require "pathname"

module FakeThemeHelpers
  def create_theme_dir(name, subdirs: [])
    theme_path = Rails.root.join("themes", name)
    FileUtils.mkdir_p(theme_path)
    subdirs.each { |sub| FileUtils.mkdir_p(theme_path.join(sub)) }
    theme_path
  end

  def cleanup_dummy_themes
    themes_dir = Rails.root.join("themes")
    return unless themes_dir.exist?

    themes_dir.children.each do |child|
      next if child.basename.to_s == ".keep"
      FileUtils.rm_rf(child)
    end
  end

  def cleanup_theme_constants(*names)
    return unless defined?(Themes)

    names.each do |name|
      const_name = name.to_s.camelize.to_sym
      Themes.send(:remove_const, const_name) if Themes.const_defined?(const_name, false)
    rescue NameError
      # Skip names that don't produce valid Ruby constant names (e.g. "my-cool-theme")
    end
    Object.send(:remove_const, :Themes) if Themes.constants.empty?
  end
end
