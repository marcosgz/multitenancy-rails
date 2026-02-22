# frozen_string_literal: true

module Multitenancy
  module Integrations
    class RSpec
      def self.call(app)
        return unless defined?(::RSpec)
        return unless ::RSpec.respond_to?(:configuration)

        # This is the list of directories RSpec was told to run.
        to_run = ::RSpec.configuration.instance_variable_get(:@files_or_directories_to_run)
        default_path = ::RSpec.configuration.default_path

        if to_run == [default_path]
          # This is the default case when you run `rspec`. We want to add all the theme's spec paths
          # to the collection of directories to run.

          theme_paths = Multitenancy.themes.map do |theme|
            spec_path = theme.relative_path.join(default_path)
            spec_path.to_s if spec_path.exist?
          end

          to_run.concat(theme_paths)
        else
          # This is when `rspec` is run with a list of directories or files. We scan this list to see
          # if any of them matches a theme's directory. If it does, we concat the `default_path` to the
          # end of it.
          #
          # themes/my_theme => themes/my_theme/spec
          #
          # If it doesn't match a theme path, we leave it alone.
          to_run.map! do |path|
            if (theme = Multitenancy.themes.find { |t| t.relative_path.to_s == path })
              [
                theme,
                *nested_themes_for(theme)
              ].map do |theme|
                spec_path = theme.relative_path.join(default_path)
                spec_path.to_s if spec_path.exist?
              end
            else
              path
            end
          end
        end

        ::RSpec.configuration.files_or_directories_to_run = to_run.flatten.compact.uniq
      end

      def self.nested_themes_for(parent_theme)
        Multitenancy.themes.select do |theme|
          theme.name != parent_theme.name && theme.name.include?(parent_theme.name)
        end
      end

    end
  end
end
