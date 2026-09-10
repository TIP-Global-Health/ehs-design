# Project Conventions

Interactive, **offline** mockups of the HealthyStart eHS dashboards. A Hugo +
Tailwind v4 single page mounts an embedded Elm app that renders two dashboards —
**Facility Performance (Dashboard II)** and **Program Monitoring (Dashboard
III)** — plus a per-KPI year/month drill-down. There is no backend and no
network: every figure lives in the Elm app (`elm/src/Data.elm`).

Source of truth for layout/content: `TIP-Global-Health/eheza-app` issues
#2230–#2236 (the HealthyStart mockup images), recoloured to eheza's live palette.

## Development

Start the dev server (finds a free port from 1313, runs the Elm + Tailwind
watchers + Hugo, all in Docker):

```bash
make dev
```

The Tailwind CLI compiles `assets/css/style.css` → `assets/css/output.css`
(gitignored); Hugo serves the compiled file.

## Hugo build

```bash
# If the dev server is already running (use the actual PORT):
docker compose exec hugo hugo --gc --minify

# Or build the gh-pages output from scratch (requires HUGO_BASEURL):
HUGO_BASEURL=https://<user>.github.io/<repo>/ make build
```

## Accessibility

All HTML targets WCAG 2.1 **AA** (eheza's brand blues clear AA but not AAA).
After modifying any HTML/layout/CSS, run pa11y (0 errors expected):

```bash
# Single page (use the actual PORT):
docker compose exec hugo npx pa11y --standard WCAG2AA --config .pa11y.json http://localhost:1313/

# All screens:
docker compose exec hugo npm run pa11y
```

pa11y only exercises the default (Facility) screen; the Program view and the
drill-down modal reuse the same components, so AA holds for them too. Add screens
to the `paths` array in `.pa11yci.js` as they are built.

## CSS

Tailwind-first. `assets/css/style.css` holds **only** config: `@import
"tailwindcss"`, the `@source` globs, the `@theme` design tokens (eheza's palette
+ Nunito), and a minimal `@layer base`. Express everything else with Tailwind
utilities in the markup — prefer a named utility over an arbitrary value when one
exists; reach for arbitrary values (`min-h-[3.25rem]`, brand hexes) only when no
close stock class exists. **Do not** add component classes.

Recolour the project by changing the `--color-*` tokens in `style.css`. The
`accent` blue is darkened just enough that white-on-accent and accent-on-white
both clear WCAG AA; the brighter brand cyan is reserved for non-text fills.

## Embedded Elm app (mock)

The homepage mounts the Elm dashboards app (`elm/src/*.elm`) into the
`[data-dashboards-app]` node. It is a **mock**: no network call. Modules:

- `Types` — model, `Msg`, the `Dashboard` / `Screen` / `Kpi` types.
- `Data` — all mock figures plus the deterministic series generator that gives
  every KPI/year a stable, distinct trend (and the drill-down cells).
- `Chart` — the generic multi-series SVG trend chart (reused by both dashboards;
  issue #2233). Series differ by colour **and** line style.
- `View` — banner, filters, tiles, KPI blocks, coverage bars, trends + alerts
  panels, and the drill-down modal.
- `Main` — `Browser.element` wiring and the two **outgoing** ports: `printPage`
  (browser print) and `exportData` (a logged stub).

Notes:

- Source is Elm 0.19.2; it compiles to `assets/javascript/vendor/elm-main.js`
  (committed, so Docker/CI builds need no Elm toolchain).
- Rebuild manually (in the container):
  `docker compose exec hugo sh -c "cd /src/elm && elm make src/Main.elm --output ../assets/javascript/vendor/elm-main.js"`.
- The `elm` service recompiles `elm-main.js` on `.elm` change; Tailwind
  (`@source` on the bundle) + Hugo then live-reload.
- Draw SVG with the `elm/svg` package (`Svg` / `Svg.Attributes`), **not**
  `Html.node "svg"` — the latter renders in the HTML namespace and won't display.

## JavaScript

JavaScript lives in `assets/javascript/*.js`, never inline in `<script>` tags in
templates (`vendor/` is generated/third-party and is ESLint-ignored). After
modifying any file there, run ESLint and expect 0 errors:

```bash
docker compose exec hugo npm run lint   # or: npm run lint:fix
```

## Code hygiene

If you come across stale code while working — a selector/class/reference that no
longer matches the markup, a dead handler, a pointer to a removed file — **fix
it, don't work around it.** Repair it to match current reality or remove it if
the feature is genuinely gone.

## Git

Commit and push freely on a feature branch — no need to ask first. Never
force-push. Don't push directly to `main` or merge a PR without explicit
approval.
