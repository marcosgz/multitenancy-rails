import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

const application = Application.start()
application.debug = false
window.Stimulus = application

// Shared controllers from the main app (data-controller="hello")
eagerLoadControllersFrom("controllers", application)

// Theme-specific controllers (overrides shared if same name)
eagerLoadControllersFrom("<%= @theme_name %>/controllers", application)
