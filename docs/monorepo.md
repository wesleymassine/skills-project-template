# Monorepo

How to use this template when one repository holds several apps. A single-app project can delete this file.

## Layout

```text
repo/
  AGENTS.md                 # rules for the whole repository + the map of apps
  docs/                     # system-wide owner documents and ADRs
  .agents/skills/           # every skill, shared and app-specific
  .claude/                  # Claude Code adapter: settings, hooks, reviewer
  scripts/verify.sh         # one entry point that dispatches to each app
  apps/
    api/
      AGENTS.md             # short: only what is specific to this app
      docs/adr/             # optional: decisions that only concern this app
    web/
      AGENTS.md
```

## One root `AGENTS.md`, one short `AGENTS.md` per app

The root file holds what applies everywhere: owner documents, workflow, commit conventions, security rules, and the map of apps. Each app's file holds only what differs in that app, and never repeats the root.

Agents load nested instruction files at different moments, and Claude Code only loads an app's `AGENTS.md` after it **reads** a file in that folder, not when it creates or edits one first. That is why the root `AGENTS.md` carries an explicit rule: read the app's `AGENTS.md` before changing anything under it.

Keep each app file around 10 to 30 lines. Everything in it costs tokens in every session that touches the app. A good app file:

```markdown
# AGENTS.md — apps/api

NestJS API on Node 22. Decisions: docs/adr/0003-api-framework.md.

## Commands
- Verify: `scripts/verify.sh quick apps/api/<files>` from the repository root (types, lint, affected tests).
- Run locally: `docker compose up api`, then http://localhost:3001.

## Rules specific to this app
- Database access only through the repositories in `src/db/`. No raw SQL in controllers.
- A merged migration is never edited. Add a new one.
- Errors leave the API in the format described in docs/adr/0005-error-format.md.

## Boundaries
- May import from `packages/shared`. Must not import from `apps/web`.
```

Leave out of app files whatever the root, the docs or the tooling already say: general coding standards, the workflow, things a linter enforces.

Never add `CLAUDE.md` or `CLAUDE.local.md` anywhere in the tree. In any folder where one exists, Claude Code reads it instead of that folder's `AGENTS.md`. `scripts/test/layout.test.sh` fails on both, and it fails when a folder under `apps/` has no `AGENTS.md`.

## Start the agent from the repository root

Claude Code does not inherit `.claude/settings.json` from parent folders. A session started inside `apps/api/` runs without the root's permissions, hooks and reviewer. Start every session from the root and name the app in the request. Path-relative deny rules like `Read(./**/.env)` also anchor at the starting folder, which is one more reason to start at the root.

## One `verify.sh`, dispatching per app

The Stop hook passes every edited file to `scripts/verify.sh quick`, from any app. Group the files by app and run each app's checks:

```bash
quick)
  declare -A by_app=()
  for f in "$@"; do
    case "$f" in
    apps/*/*) app=${f#apps/}; app=${app%%/*}; by_app[$app]+="${f#apps/$app/} " ;;
    esac
  done
  for app in "${!by_app[@]}"; do
    (cd "apps/$app" && case "$app" in
      api) npx tsc --noEmit && npx eslint ${by_app[$app]} && npx vitest related --run ${by_app[$app]} ;;
      web) npx tsc --noEmit && npx eslint ${by_app[$app]} ;;
    esac) || exit 1
  done
  ;;
```

`declare -A` needs bash 4+. macOS ships bash 3.2, so install a newer bash or pin it with mise. Turborepo, Nx or `pnpm --filter` can do the same grouping if the repository already uses them.

## CI per app

Run each app's `full` checks only when the app changed, but keep one required check name for branch protection:

```yaml
verify:
  if: hashFiles('scripts/init.sh') == ''
  runs-on: ubuntu-latest
  strategy:
    matrix:
      app: [api, web]
  steps:
    - uses: actions/checkout@v4
      with: { fetch-depth: 0 }
    - uses: jdx/mise-action@v2
    - run: |
        base=${{ github.event.pull_request.base.sha || 'HEAD~1' }}
        if git diff --quiet "$base" -- "apps/${{ matrix.app }}" packages/; then
          echo "apps/${{ matrix.app }} unchanged"; exit 0
        fi
        scripts/verify.sh full ${{ matrix.app }}
```

## Domain language and decisions

- **One domain across all apps:** a single `GLOSSARY.md` and `docs/adr/` at the root, as in a single-app project.
- **Apps with different domains** (billing vs catalog): `domain-modeling` supports a `GLOSSARY-MAP.md` at the root that points to one `GLOSSARY.md` per context. System-wide ADRs stay in the root `docs/adr/`; decisions that only concern one app go in `apps/<app>/docs/adr/`.

## Skills

Keep every skill in the root `.agents/skills/`, so all agents find them and `skills-lock.json` stays the single record. Name app-specific skills after the app (`api-testing`, `web-components`) and start their description with the path ("Use when writing tests in apps/api/"), so the agent picks them only for that app.

## Ownership and cost

- **CODEOWNERS per app:** add lines such as `/apps/api/ @your-org/backend` under the harness lines.
- **Commits:** prefix the subject with the app, as in `api: add rate limiting`.
- **Personal focus:** a developer who never touches some apps can skip their instructions with `claudeMdExcludes` in `.claude/settings.local.json` (personal, ignored).
- **Generated and vendored code:** add `Read` deny rules for committed generated files, such as `Read(./**/*.generated.*)`, so agents don't spend tokens reading them.
- **Large codebases:** a code intelligence plugin (language server) lets Claude Code find definitions and references without reading files one by one.

Sources: [Claude Code: monorepos and large codebases](https://code.claude.com/docs/en/large-codebases), [Claude Code: AGENTS.md](https://code.claude.com/docs/en/memory#agents-md).
