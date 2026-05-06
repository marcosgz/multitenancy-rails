# ViewComponent

Theme-aware component rendering. Each theme can override any shared component by defining one with the same base name in its own namespace; `theme_component(:foo)` resolves the override first and falls back to the shared component.

**Requires:** [`view_component`](https://viewcomponent.org/) gem. The integration is guard-clause skipped when the gem is absent.

## Layout

Shared components live in the host's `app/components/`. Theme overrides live in `themes/<name>/app/components/` and are autoloaded under `Themes::<Name>`:

```
app/components/
└── story_card_component.rb              # StoryCardComponent (shared default)

themes/community/app/components/
└── story_card_component.rb              # Themes::Community::StoryCardComponent (override)

themes/storefront/app/components/        # No override — falls back to shared
```

The autoload path is wired automatically — `app/components` is in `Multitenancy.config.paths` by default, so theme directories register with Zeitwerk under their namespace at boot.

## Usage

Render via the `theme_component` helper, available in every controller and view:

```erb
<%= render theme_component(:story_card, story: @story, variant: :hero) %>
```

The first argument is the component's base name (snake-case symbol or string). Resolution order:

1. `Themes::<CurrentTheme>::<Name>Component` — theme override
2. `<Name>Component` — shared default

The active theme is derived from the calling controller's class namespace (`Themes::Community::HomeController#module_parent.name` → `"community"`). For controllers outside any `Themes::` namespace (e.g., main app), the helper falls through to the shared component.

## Caching

Resolutions are cached per `[theme, name]` pair using `Concurrent::Map`. The cache is cleared automatically on each Rails reload, so overrides added or removed in development are picked up without a server restart.

## Example: shared + override

**Shared component** (`app/components/story_card_component.rb`):

```ruby
class StoryCardComponent < ViewComponent::Base
  def initialize(story:)
    @story = story
  end
end
```

**Theme override** (`themes/community/app/components/story_card_component.rb`):

```ruby
module Themes::Community
  class StoryCardComponent < ::StoryCardComponent
    # Override template only — inherits behavior. Or override behavior too.
  end
end
```

**Template** (theme override, `themes/community/app/components/story_card_component.html.erb`):

```erb
<article class="community-story-card">
  <h3><%= @story.title %></h3>
</article>
```

Calling `render theme_component(:story_card, story: @story)` from a `Themes::Community::*` controller renders the community variant. The same call from a controller in another theme — or with no override defined for the current theme — renders the shared component.

## Host-side base class

This integration intentionally does not provide a `Multitenancy::Component` base class. Hosts that want to expose context (current site, current user, request locale) to all components should define their own `ApplicationComponent` and have shared components inherit from it:

```ruby
# app/components/application_component.rb
class ApplicationComponent < ViewComponent::Base
  private

  def current_site
    Current.site
  end
end
```
