# Multitenancy brand kit

## The mark

One request comes in from the left and forks to one of several sites: each host resolves to a site, each site to its theme. The blue dot is the site answering this request.

## Colours

| Role  | Light background | Dark background |
|-------|------------------|-----------------|
| Ink   | `#1a2233`        | `#e3e9f3`       |
| Blue | `#4a7bec`        | `#4a7bec`        |
| Tile (app icons) | `#1a2233` | `#1a2233` |

Blue is reserved for the answering site and the rule under "RAILS". The ink and line weight match the Lepus kit, so the libraries read as one family.

## Clear space and minimum size

- Clear space: keep at least a quarter of the mark's height empty on every side.
- `mark*.svg`: 48 px and up.
- `mark-small*.svg` / `favicon.svg`: 16 to 48 px. Its line is heavier so it stays sharp at favicon sizes. Do not use it large.
- `lockup-multitenancy*`: 150 px wide minimum. `lockup-multitenancy-rails*`: 200 px wide minimum (below that, "RAILS" gets too small; use `lockup-multitenancy` or the mark alone).

## Which file where

| Use | File |
|-----|------|
| README header | `lockup-multitenancy-rails-on-light.svg` + `lockup-multitenancy-rails-on-dark.svg` in a `<picture>` (below) |
| Web page header that follows the OS theme | `lockup-multitenancy.svg`, `mark.svg` (ink switches with `prefers-color-scheme`) |
| Inline in an app that sets its own text colour | `*-mono.svg` (everything is `currentColor`) |
| Fixed background you control | `*-on-light.svg` / `*-on-dark.svg` |
| Browser tab | `favicon.svg` (adaptive), with `favicon.ico` (16/32/48) as fallback |
| iOS home screen | `apple-touch-icon.png` (180, solid tile) |
| Web manifest / PWA | `icon-512.png` (solid tile, mark inside the maskable safe zone) |
| Legacy PNG favicons | `favicon-16.png`, `favicon-32.png` (transparent, light-background ink) |

All wordmark text is outlined Overpass (SIL Open Font License), so no font is needed to render it.

### README

GitHub follows the viewer's GitHub theme only through `<picture>`, so use the light/dark pair rather than the adaptive file:

```html
<h1 align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/brand/lockup-multitenancy-rails-on-dark.svg">
    <img alt="Multitenancy for Rails" src="docs/brand/lockup-multitenancy-rails-on-light.svg" width="532">
  </picture>
</h1>
```

### HTML head

```html
<link rel="icon" href="/favicon.ico" sizes="48x48">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
```

## Don'ts

- Don't redraw the wordmark in live text or another typeface.
- Don't stretch, rotate, outline or add effects to the mark.
- Don't put the ink mark on mid-tone or busy backgrounds; use the tile or the mono file instead.
- Don't recolour the line in the accent or put the dot in ink (except in the mono files).
