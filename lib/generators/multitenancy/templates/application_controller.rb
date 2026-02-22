# frozen_string_literal: true

module <%= @theme_namespace %>
  class ApplicationController < ActionController::Base
    include Multitenancy::Controller
  end
end
