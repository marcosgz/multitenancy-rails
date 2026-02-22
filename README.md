# Multitenancy

A Rails engine-based multitenancy gem that provides theme isolation through dynamically created Rails engines. Each theme lives in its own directory under `themes/` and gets its own namespace, routes, controllers, views, assets, JavaScript, and locales — all automatically discovered and wired up at boot time.

## Installation

Add the gem to your `Gemfile`:

```ruby
gem "multitenancy-rails", path: "vendor/gems/multitenancy"
```

## Quick start

Generate a new theme:

```bash
bin/rails generate multitenancy my_store
```

Mount the themes in your routes (`config/routes.rb`):

```ruby
Rails.application.routes.draw do
  draw(:multitenancy)

  root "home#index"
end
```

Create the route drawing file at `config/routes/multitenancy.rb`:

```ruby
Multitenancy.themes.each do |theme|
  mount theme.engine, at: theme.mount_path
end
```

Start the server and visit `/my-store` to see the theme in action.

## Theme directory structure

Each theme is a self-contained directory under `themes/` that mirrors a Rails application structure:

```
themes/my_store/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   └── home_controller.rb
│   ├── views/
│   │   ├── layouts/
│   │   │   └── application.html.erb
│   │   └── home/
│   │       └── index.html.erb
│   ├── assets/
│   │   └── stylesheets/my-store/
│   │       └── application.css
│   └── javascript/my-store/           # When using importmap
│       ├── application.js
│       └── controllers/
│           └── hello_controller.js
├── config/
│   ├── routes.rb
│   ├── importmap.rb                   # When using importmap
│   └── locales/
│       └── en.yml
└── spec/
    └── factories/                     # When using FactoryBot
```

## How it works

### Boot sequence

The gem hooks into Rails through a Railtie and initializes in two phases:

**Phase 1 — `before_configuration`:**

1. **Rails integration** discovers all directories under `themes/` and bootstraps each one:
   - Creates a Ruby module namespace (e.g., `Themes::MyStore`)
   - Creates a `Rails::Engine` subclass at `Themes::MyStore::Engine`
   - Registers autoload paths with Zeitwerk (controllers, models, services, etc.)
   - Registers asset paths with Propshaft
2. **FactoryBot integration** adds each theme's `spec/factories` to the factory lookup paths
3. **RSpec integration** configures theme spec directories for automatic discovery

**Phase 2 — `after_initialize`:**

4. **Importmap integration** creates per-theme importmaps with development file watchers
5. **TailwindCSS integration** excludes raw Tailwind input files from Propshaft and prepares build output directories

### Theme engine

Each theme gets a dynamically created `Rails::Engine` configured via the `Stim` module. The engine provides:

- **Isolated namespace** — theme classes live under `Themes::<Name>` and never collide with each other or the main app
- **Own root path** — the engine's root is the theme directory itself
- **View paths** — `app/views` within the theme
- **Asset paths** — `app/assets` registered with Propshaft
- **Locale paths** — `config/locales` for per-theme I18n
- **JavaScript paths** — `app/javascript` for importmap/Stimulus support

### Controller concern

Theme controllers include `Multitenancy::Controller`, which:

- Prepends the theme's `app/views` directory to the view lookup path so theme views take priority
- Sets `layout "application"` to use the theme's own layout
- Strips the namespace prefix from controller prefixes so views resolve naturally (e.g., `home/index` instead of `themes/my_store/home/index`)

```ruby
module Themes::MyStore
  class ApplicationController < ActionController::Base
    include Multitenancy::Controller
  end
end
```

### Routing

Themes define their own routes inside their engine:

```ruby
# themes/my_store/config/routes.rb
Themes::MyStore::Engine.routes.draw do
  root "home#index"
end
```

All theme engines are mounted automatically by the `config/routes/multitenancy.rb` draw file. Each theme is mounted at `/<theme-name>`:

| Theme directory    | Mount path    | Root URL                |
|--------------------|---------------|-------------------------|
| `themes/my_store`  | `/my-store`   | `http://localhost:3000/my-store` |
| `themes/community` | `/community`  | `http://localhost:3000/community` |

### Autoload paths

The following directories inside a theme are automatically registered with Zeitwerk under the theme's namespace:

- `app/controllers`
- `app/channels`
- `app/helpers`
- `app/services`
- `app/structs`
- `app/models`
- `app/mailers`
- `lib`

This means you can add models, services, or any other classes to a theme and they will be autoloaded under the `Themes::<Name>` namespace.

## Generator

```
bin/rails generate multitenancy NAME [options]
```

### Arguments

| Argument | Description |
|----------|-------------|
| `NAME`   | Name of the theme (will be parameterized) |

### Options

| Option          | Type    | Default | Description |
|-----------------|---------|---------|-------------|
| `--importmap`   | boolean | `true`  | Generate importmap configuration and Stimulus setup |
| `--tailwindcss` | boolean | `false` | Generate Tailwind CSS configuration instead of plain CSS |

### Examples

Generate a theme with importmap (default):

```bash
bin/rails generate multitenancy blog
```

Generate a theme with Tailwind CSS and importmap:

```bash
bin/rails generate multitenancy blog --tailwindcss
```

Generate a theme without importmap:

```bash
bin/rails generate multitenancy blog --no-importmap
```

Generate a theme with Tailwind CSS and no importmap:

```bash
bin/rails generate multitenancy blog --tailwindcss --no-importmap
```

## Integrations

### Importmap

**Requires:** `importmap-rails` gem

Each theme gets its own `Importmap::Map` instance stored on `Themes::<Name>::Engine.importmap`. The integration:

1. Draws the main app's importmap first (Turbo, Stimulus, shared libraries)
2. Draws the theme's `config/importmap.rb` on top — theme pins can override app pins
3. In development, watches theme JavaScript directories and reloads the importmap on changes
4. Removes theme importmap paths from the main app's config to prevent cross-contamination

**Theme importmap example** (`themes/blog/config/importmap.rb`):

```ruby
pin "blog/application", to: "blog/application.js"

pin_all_from "themes/blog/app/javascript/blog/controllers",
  under: "blog/controllers", to: "blog/controllers"
```

**Theme layout usage:**

```erb
<%= javascript_importmap_tags "blog/application", importmap: Themes::Blog::Engine.importmap %>
```

**Theme application.js** — loads shared controllers from the main app plus theme-specific ones:

```javascript
import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

const application = Application.start()
application.debug = false
window.Stimulus = application

// Shared controllers from the main app (data-controller="hello")
eagerLoadControllersFrom("controllers", application)

// Theme-specific controllers (overrides shared if same name)
eagerLoadControllersFrom("blog/controllers", application)
```

This setup allows themes to use all shared Stimulus controllers from the main app while also defining or overriding controllers specific to the theme.

### Tailwind CSS

**Requires:** `tailwindcss-rails` gem (`~> 4.4`)

The Tailwind CSS integration compiles per-theme stylesheets using Tailwind CSS v4's CSS-first configuration. No `tailwind.config.js` is needed.

**File layout with Tailwind:**

```
themes/blog/
└── app/assets/
    ├── tailwind/blog/
    │   └── application.css          # Tailwind input (raw @import directives)
    └── builds/blog/
        └── application.css          # Compiled output (served by Propshaft)
```

**Tailwind input file** (`app/assets/tailwind/blog/application.css`):

```css
@import "tailwindcss";
@source "../../../views/**/*.html.erb";
@source "../../../controllers/**/*.rb";
@source "../../../javascript/blog/**/*.js";
```

The `@source` directives use relative paths from the input file's location to scan only the theme's own files for utility classes. Each theme is independently scoped.

The integration automatically:
- Excludes the `tailwind/` directory from Propshaft (raw `@import` files cannot be served directly)
- Creates the `builds/<name>/` output directory
- Skips entirely if `tailwindcss-rails` is not in the bundle (guard clause)

**Layout usage** — no changes needed, the existing `stylesheet_link_tag` resolves to the compiled output:

```erb
<%= stylesheet_link_tag "blog/application", "data-turbo-track": "reload" %>
```

#### Rake tasks

**`multitenancy:tailwindcss:build`** — compiles Tailwind CSS for all themes:

```bash
bin/rails multitenancy:tailwindcss:build
```

This task is automatically hooked into `assets:precompile`, so production deploys (Kamal, Heroku, etc.) compile theme CSS without any extra configuration.

**`multitenancy:tailwindcss:watch`** — watches and recompiles on changes (for development):

```bash
bin/rails multitenancy:tailwindcss:watch
```

Spawns a separate watcher process per theme. Ctrl-C cleanly terminates all watchers.

#### Development setup

To run the Tailwind watcher alongside the Rails server during development, use a `Procfile.dev`:

```procfile
web: bin/rails server
tailwind: bin/rails multitenancy:tailwindcss:watch
```

Then start everything with:

```bash
bin/dev
```

Or run the watcher in a separate terminal:

```bash
bin/rails multitenancy:tailwindcss:watch
```

### RSpec

**Requires:** `rspec-rails` gem

The RSpec integration automatically discovers and includes theme specs in test runs:

- **`rspec`** (no arguments) — runs `spec/` from the main app plus `spec/` from every theme
- **`rspec themes/blog`** — expands to `themes/blog/spec` automatically
- **Nested themes** — if theme names share a prefix (e.g., `blog` and `blog-admin`), running `rspec themes/blog` also includes `themes/blog-admin/spec`

No configuration needed. Theme specs are discovered as long as a `spec/` directory exists inside the theme.

### FactoryBot

**Requires:** `factory_bot_rails` gem

Automatically adds each theme's `spec/factories` directory to FactoryBot's definition file paths. Theme factories are available in all tests without any extra configuration.

```
themes/blog/
└── spec/
    └── factories/
        └── posts.rb    # Automatically loaded by FactoryBot
```

## Localization

Each theme has its own locale files under `config/locales/`. Theme translations are namespaced under `themes.<name>`:

```yaml
# themes/blog/config/locales/en.yml
en:
  themes:
    blog:
      hello: "Hello world from the blog theme"
```

Usage in theme views:

```erb
<%= t("themes.blog.hello") %>
```

## Configuration

### Autoload paths

The list of directories that get registered with Zeitwerk for each theme can be customized:

```ruby
# In an initializer or before configuration
Multitenancy.config.paths = %w[
  app/controllers
  app/channels
  app/helpers
  app/services
  app/structs
  app/models
  app/mailers
  lib
]
```

Only directories that actually exist within a theme are registered.

### ActiveSupport hook

The gem fires an `ActiveSupport` load hook during initialization that other gems or application code can use to hook into:

```ruby
ActiveSupport.on_load(:multitenancy) do |multitenancy|
  # Custom initialization after all themes are bootstrapped
end
```

## Full example

Create a new theme with all integrations:

```bash
bin/rails generate multitenancy storefront --tailwindcss
```

This generates:

```
themes/storefront/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   └── home_controller.rb
│   ├── views/
│   │   ├── layouts/
│   │   │   └── application.html.erb
│   │   └── home/
│   │       └── index.html.erb
│   ├── assets/
│   │   ├── tailwind/storefront/
│   │   │   └── application.css
│   │   └── builds/storefront/
│   │       └── .keep
│   └── javascript/storefront/
│       ├── application.js
│       └── controllers/
│           └── hello_controller.js
├── config/
│   ├── routes.rb
│   ├── importmap.rb
│   └── locales/
│       └── en.yml
```

Build and serve:

```bash
# Compile Tailwind CSS
bin/rails multitenancy:tailwindcss:build

# Start the server
bin/rails server

# Visit http://localhost:3000/storefront
```

Add a new controller to the theme:

```ruby
# themes/storefront/app/controllers/products_controller.rb
module Themes::Storefront
  class ProductsController < ApplicationController
    def index
      @products = Product.all  # Access main app models
    end
  end
end
```

Add a route:

```ruby
# themes/storefront/config/routes.rb
Themes::Storefront::Engine.routes.draw do
  root "home#index"
  resources :products, only: [:index, :show]
end
```

Add a Stimulus controller specific to this theme:

```javascript
// themes/storefront/app/javascript/storefront/controllers/cart_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count"]

  add() {
    this.countTarget.textContent = parseInt(this.countTarget.textContent) + 1
  }
}
```

Use it in a theme view — the controller is scoped to this theme only:

```erb
<!-- themes/storefront/app/views/products/index.html.erb -->
<div data-controller="storefront--cart">
  <span data-storefront--cart-target="count">0</span>
  <button data-action="storefront--cart#add">Add to cart</button>
</div>
```

## Requirements

- Ruby >= 3.1
- Rails (railties, activesupport)
- Zeitwerk (for autoloading)

### Optional dependencies

| Gem                | Integration    | Purpose                          |
|--------------------|----------------|----------------------------------|
| `importmap-rails`  | Importmap      | Per-theme JavaScript with ESM    |
| `tailwindcss-rails` | TailwindCSS   | Per-theme Tailwind CSS builds    |
| `rspec-rails`      | RSpec          | Auto-discover theme specs        |
| `factory_bot_rails`| FactoryBot     | Auto-discover theme factories    |

All integrations use guard clauses and are silently skipped when their respective gems are not installed.

## License

MIT
