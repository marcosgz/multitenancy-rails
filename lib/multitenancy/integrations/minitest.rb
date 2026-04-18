# frozen_string_literal: true

module Multitenancy
  module Integrations
    class Minitest
      def self.call(app)
        return unless defined?(::Minitest)
        return unless defined?(::Rails::TestUnit::Runner)

        integration = self

        ::Rails::TestUnit::Runner.singleton_class.prepend(Module.new do
          define_method(:load_tests) do |argv|
            if argv.any?
              # Explicit paths: expand theme directory paths to their test/ subdirs,
              # including nested themes (e.g. themes/alpha also picks up themes/alpha-v2).
              expanded = argv.flat_map do |path|
                if (theme = Multitenancy.themes.find { |t| t.relative_path.to_s == path })
                  [theme, *integration.nested_themes_for(theme)].filter_map do |t|
                    test_path = t.relative_path.join("test")
                    test_path.to_s if test_path.exist?
                  end
                else
                  path
                end
              end
              super(expanded)
            else
              # Default run (rails test with no args): load main app tests first,
              # then load each theme's test/ directory separately.
              theme_test_dirs = Multitenancy.themes.filter_map do |theme|
                test_path = theme.relative_path.join("test")
                test_path.to_s if test_path.exist?
              end
              super(argv)
              super(theme_test_dirs) unless theme_test_dirs.empty?
            end
          end
        end)
      end

      def self.nested_themes_for(parent_theme)
        Multitenancy.themes.select do |theme|
          theme.name != parent_theme.name && theme.name.include?(parent_theme.name)
        end
      end
    end
  end
end
