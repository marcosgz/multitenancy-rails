# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run all tests and linting (default task)
bundle exec rake

# Run tests only
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/multitenancy/theme_spec.rb

# Run a single example by line number
bundle exec rspec spec/multitenancy/theme_spec.rb:42

# Lint
bundle exec standardrb

# Auto-fix lint issues
bundle exec standardrb --fix
```

## Architecture

This is a Rails gem that implements multitenancy via **per-theme Rails Engines** created dynamically at boot time. Each theme under `themes/` in the host app gets its own isolated engine, namespace, autoload paths, views, assets, and routes.

### Core flow

1. **`Multitenancy::Railtie`** hooks into `before_configuration` and `after_initialize`.
2. During `before_configuration`, `Integrations::Rails` calls `Theme#bootstrap(app)` for every directory under `themes/`.
3. `Theme#bootstrap` creates a Ruby module (`Themes::MyStore`), then a `Rails::Engine` subclass (`Themes::MyStore::Engine`) by calling `Theme#create_engine`, which includes a `Stim` instance as a mixin.
4. **`Stim`** (a `Module` subclass) is the engine configurator: it sets `called_from`, `isolate_namespace`, `config.root`, and registers `app/views`, `app/assets`, `config/locales`, `app/javascript` paths on the engine.
5. `Theme#inject_paths` registers the theme's autoload directories (controllers, models, services, etc.) with Zeitwerk under the theme's namespace, and adds `app/javascript` to Propshaft's asset paths.

### Key files

| File | Role |
|------|------|
| `lib/multitenancy.rb` | Entry point; defines `Multitenancy.themes`, `config.paths`, and triggers Railtie load |
| `lib/multitenancy/theme.rb` | Represents one theme; owns bootstrap, namespace/engine creation, path injection |
| `lib/multitenancy/stim.rb` | `Module` subclass used as an `include`-able engine configurator |
| `lib/multitenancy/controller.rb` | `ActiveSupport::Concern` included in theme application controllers; fixes view path and strips namespace from `_prefixes` |
| `lib/multitenancy/railtie.rb` | Wires integrations into the Rails boot lifecycle |
| `lib/multitenancy/integrations/` | Optional integrations (Importmap, TailwindCSS, RSpec, FactoryBot) — each uses a guard clause and is silently skipped if its gem is absent |

### Test setup

Specs run against a dummy Rails app at `spec/dummy/`. The `spec_helper.rb`:
- Sets `Multitenancy.root` to the dummy app root before each example
- Calls `Multitenancy.reset!` to clear the themes cache
- Stubs `autoloaders.main.push_dir` to avoid real Zeitwerk side effects
- Cleans up dynamically created `Themes::*` constants after each example

The `FakeThemeHelpers` and `RailsStateCleanup` support modules in `spec/support/` provide helpers for creating temporary theme directory structures in tests and restoring Rails global state.

### Integration pattern

Each integration in `lib/multitenancy/integrations/` follows the same pattern: a class with a single `.call(app)` class method, guarded at the top against the optional gem not being present. New integrations should follow this convention.


### Commits and Pull Requests

Commits and pull requests should be brief and to the point. Do not include "Co-authored-by" or mention Claude, Codex, OpenCode, Crush in commit messages.
