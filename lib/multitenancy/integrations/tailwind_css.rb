# frozen_string_literal: true

module Multitenancy
  module Integrations
    class TailwindCss
      def self.call(app)
        return unless defined?(::Tailwindcss)

        Multitenancy.themes.each do |theme|
          tailwind_dir = theme.path.join("app/assets/tailwind")
          next unless tailwind_dir.exist?

          # Exclude raw Tailwind input files from Propshaft — they contain
          # @import directives that can't be served directly.
          app.config.assets.excluded_paths << tailwind_dir

          # Ensure the builds output directory exists so the compiled CSS
          # can be picked up by Propshaft.
          builds_dir = theme.path.join("app/assets/builds/#{theme.name}")
          FileUtils.mkdir_p(builds_dir)
        end
      end

      def self.compilation_targets
        return [] unless defined?(::Tailwindcss)

        Multitenancy.themes.each_with_object([]) do |theme, targets|
          input = theme.path.join("app/assets/tailwind/#{theme.name}/application.css")
          next unless input.exist?

          output = theme.path.join("app/assets/builds/#{theme.name}/application.css")
          targets << { theme: theme, input: input, output: output }
        end
      end

      def self.compile_command(target, debug: false)
        args = [
          Tailwindcss::Ruby.executable,
          "--input", target[:input].to_s,
          "--output", target[:output].to_s
        ]
        args << "--minify" unless debug
        args
      end

      def self.watch_command(target, debug: false)
        compile_command(target, debug: debug) + ["--watch"]
      end
    end
  end
end
