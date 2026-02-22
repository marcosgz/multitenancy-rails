# frozen_string_literal: true

module Multitenancy
  module Integrations
    class FactoryBot
      def self.call(app)
        return unless app.config.respond_to?(:factory_bot)

        Multitenancy.themes.each do |theme|
          app.config.factory_bot.definition_file_paths << theme.relative_path.join("spec/factories").to_s
        end
      end
    end
  end
end
