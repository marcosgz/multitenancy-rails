# frozen_string_literal: true

require "rails/generators"
require "rails/generators/base"

module Multitenancy
  class MultitenancyGenerator < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)

    argument :theme_name, type: :string, desc: "Name of the theme to generate"
    class_option :importmap, type: :boolean, default: true, desc: "Generate importmap configuration"
    class_option :tailwindcss, type: :boolean, default: false, desc: "Generate Tailwind CSS configuration"

    def create_theme_structure
      @theme_name = theme_name.parameterize
      @theme_class_name = theme_name.camelize
      @theme_namespace = "Themes::#{@theme_class_name}"

      create_directories
      create_controllers
      create_views
      create_assets
      create_config_files
    end

    private

    def create_directories
      dirs = %w[
        app/controllers
        app/views/home
        app/views/layouts
        config/locales
      ]

      if options[:tailwindcss]
        dirs << "app/assets/tailwind/#{@theme_name}"
        dirs << "app/assets/builds/#{@theme_name}"
      else
        dirs << "app/assets/stylesheets/#{@theme_name}"
      end

      dirs.each do |dir|
        empty_directory File.join("themes", @theme_name, dir)
      end

      if options[:importmap]
        empty_directory File.join("themes", @theme_name, "app/javascript/#{@theme_name}")
        empty_directory File.join("themes", @theme_name, "app/javascript/#{@theme_name}/controllers")
      end
    end

    def create_controllers
      template "application_controller.rb", File.join("themes", @theme_name, "app/controllers/application_controller.rb")
      template "home_controller.rb", File.join("themes", @theme_name, "app/controllers/home_controller.rb")
    end

    def create_views
      template "layouts/application.html.erb", File.join("themes", @theme_name, "app/views/layouts/application.html.erb")
      template "home/index.html.erb", File.join("themes", @theme_name, "app/views/home/index.html.erb")
    end

    def create_assets
      if options[:tailwindcss]
        template "tailwind/application.css", File.join("themes", @theme_name, "app/assets/tailwind/#{@theme_name}/application.css")
        create_file File.join("themes", @theme_name, "app/assets/builds/#{@theme_name}/.keep")
      else
        template "stylesheets/application.css", File.join("themes", @theme_name, "app/assets/stylesheets/#{@theme_name}/application.css")
      end

      if options[:importmap]
        template "javascript/application.js", File.join("themes", @theme_name, "app/javascript/#{@theme_name}/application.js")
        template "javascript/controllers/hello_controller.js",
          File.join("themes", @theme_name, "app/javascript/#{@theme_name}/controllers/hello_controller.js")
      end
    end

    def create_config_files
      template "routes.rb", File.join("themes", @theme_name, "config/routes.rb")
      template "locales/en.yml", File.join("themes", @theme_name, "config/locales/en.yml")

      if options[:importmap]
        template "importmap.rb", File.join("themes", @theme_name, "config/importmap.rb")
      end
    end
  end
end

