# frozen_string_literal: true

<%= @theme_namespace %>::Engine.routes.draw do
  root "home#index"
end

