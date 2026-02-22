pin "<%= @theme_name %>/application", to: "<%= @theme_name %>/application.js"

pin_all_from "themes/<%= @theme_name %>/app/javascript/<%= @theme_name %>/controllers",
  under: "<%= @theme_name %>/controllers", to: "<%= @theme_name %>/controllers"
