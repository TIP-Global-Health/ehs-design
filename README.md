# eHS Dashboards — Interactive Mockup

Interactive, **offline** mockups of the HealthyStart eHS analytics dashboards,
built with Hugo + Tailwind v4 and an embedded Elm app. No backend, no network:
every figure is generated inside the Elm app so the whole thing runs as a static
site.

Two dashboards are mocked, matching the HealthyStart mockups in
[`TIP-Global-Health/eheza-app`](https://github.com/TIP-Global-Health/eheza-app)
issues #2230–#2236, recoloured to eheza's live palette:

- **Dashboard II — Facility Performance** (single intervention site): summary
  tiles, six KPI blocks (current vs. programme target vs. inter-site average),
  Aspirin/Calcium/SQLNS coverage bars, a multi-series trend chart, and a
  critical-alerts panel.
- **Dashboard III — Program Monitoring** (aggregated across all sites): the same
  shape with "% of sites exceeding threshold" tiles and a two-series trend.

Both support the **year/month drill-down**: click any KPI block (or threshold
tile) to open the per-month detail table over the dimmed dashboard.

A slim bar at the top switches between the two dashboards — a mock convenience
standing in for the two separate real logins (which are out of scope here).

## What's inside

- **Hugo** static site (single page) that mounts the Elm app.
- **Tailwind v4** — stock utilities plus eheza's palette as a handful of
  `--color-*` tokens in `assets/css/style.css`. WCAG 2.1 **AA** target.
- **Elm 0.19.2** app (`elm/src/`):
  - `Types` / `Data` — the model and all mock figures (a small deterministic
    generator gives every KPI/year a stable, distinct trend).
  - `Chart` — the generic multi-series SVG trend chart (issue #2233).
  - `View` / `Main` — screens, navigation, and the two outgoing ports
    (`printPage`, `exportData`). It compiles to
    `assets/javascript/vendor/elm-main.js` (committed, so Docker/CI need no Elm
    toolchain).
- **Docker Compose** dev stack (Hugo + Tailwind + Elm watchers).
- **CI**: ESLint, pa11y (WCAG 2.1 AA), and a GitHub Pages build/deploy.

## Development

```bash
make dev   # docker compose up; finds a free port from 1313
```

Runs the Tailwind watcher (`style.css` → `output.css`), the Hugo dev server, and
the Elm watcher (recompiles the embedded app on `.elm` change).

Rebuild the Elm bundle manually (in the container):

```bash
docker compose exec hugo sh -c "cd /src/elm && elm make src/Main.elm --output ../assets/javascript/vendor/elm-main.js"
```

## Accessibility

Target is WCAG 2.1 AA (eheza's brand blues clear AA but not AAA). Once the dev
server is up:

```bash
docker compose exec hugo npm run pa11y
```

## Lint

```bash
docker compose exec hugo npm run lint   # or: npm run lint:fix
```

## Build / deploy (GitHub Pages)

The base URL is required and not hard-coded. CI derives it from the repo
context; locally:

```bash
HUGO_BASEURL=https://<user>.github.io/<repo>/ make build
```
