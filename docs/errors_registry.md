# Errors registry (discourse-youtrack)

Notes for plugin UI and deployment troubleshooting. New entries at the top.

Format: Symptom → Cause → Fix → Context.

---

<a id="err-004"></a>

## ERR-004 - Job not found: `jobs/` instead of `app/jobs/`

**Symptom.** Post is created with `discourse_youtrack_sync_status=pending`, but status never changes. `Jobs.enqueue(:sync_post_to_youtrack, ...)` does nothing. In `rails runner`: `uninitialized constant Jobs::SyncPostToYoutrack`.

**Cause.** In current Discourse, plugin jobs autoload from `plugins/<name>/app/jobs/{regular,scheduled}/`, not from root `jobs/`. A file in `jobs/regular/sync_post_to_youtrack.rb` lands on disk but the constant never appears at runtime.

**Fix.** Keep the job in `app/jobs/regular/sync_post_to_youtrack.rb`. After moving, restart unicorn (full precompile not required for Ruby-only changes).

**Context.** Docker Discourse install, pingback smoke test.

---

<a id="err-003"></a>

## ERR-003 - `SKIP_EMBER_CLI_COMPILE=1` does not refresh plugin JS

**Symptom.** Container has the new `.gjs` / `.hbs` on disk, but the browser (and `public/assets/js/plugins/discourse-youtrack_main.*.js`) still serves the old compiled template. Checkbox / connector looks undeployed.

**Cause.** `assets:precompile` with `SKIP_EMBER_CLI_COMPILE=1` skips rebuilding plugin frontend bundles. Fine for CSS or partial cache, not for connector/initializer JS changes.

**Fix.** After edits in `assets/javascripts/`:

1. Remove old artifacts: `public/assets/js/plugins/discourse-youtrack_*` and if needed `tmp/cache/assets`
2. Full `RAILS_ENV=production bundle exec rake assets:precompile` **without** `SKIP_EMBER_CLI_COMPILE=1` (as `discourse` user in the container)
3. `sv restart unicorn`
4. Hard refresh in the browser; `discourse-youtrack_main.*.js` hash should change

**Context.** Docker Discourse install. Related to ERR-001 / ERR-002: disk looked correct while runtime still ran the old bundle.

---

<a id="err-002"></a>

## ERR-002 - Connector `composer-fields-below`: use `@outletArgs.model`, not `composer.model`

**Symptom.** No YouTrack checkbox or muted «issue not found» hint in reply composer. Topic API still returns `discourse_youtrack_issue_id`. No UI errors.

**Cause.** Outlet in Discourse core (`composer-container.gjs`) passes:

```text
@outletArgs={{lazyHash model=this.composer.model}}
```

A template using `@outletArgs.composer.model...` always gets `undefined` and renders nothing. Working connectors (e.g. discourse-ai `composer-fields`) use `args.model` / `@outletArgs.model`.

**Fix.** In the connector:

- `@outletArgs.model.topic.discourse_youtrack_issue_id`
- `@outletArgs.model.discourseYoutrackSyncRequested`
- `@outletArgs.model.action`

After template changes, run full asset precompile (see ERR-003).

**Context.** File: `assets/javascripts/discourse/connectors/composer-fields-below/discourse-youtrack-sync.gjs`.

---

<a id="err-001"></a>

## ERR-001 - Plugin JS fails to load: `Could not find module @ember/component/input`

**Symptom.** No checkbox in composer. `discourse_youtrack_enabled` is true, topic has `discourse_youtrack_issue_id`. `discourse-youtrack_main.*.js` downloads, but:

- `requirejs.entries` has no `discourse/plugins/discourse-youtrack/...` keys
- `connectorsFor("composer-fields-below")` is empty
- composer model lacks `discourseYoutrackSyncRequested` (initializer never ran)

Dynamic `import` of the bundle fails with:

```text
Could not find module `@ember/component/input` imported from `(require)`
```

**Cause.** In Discourse 8 plugin runtime via `moduleBroker` there is no separate `@ember/component/input` module. Use `@ember/component` with named export `Input`, or `@ember/modifier` (`on`) and `@ember/object` (`action`). Importing `import Input from "@ember/component/input"` in a `.gjs` connector breaks the **entire** plugin bundle on load — connector and initializer.

**Fix.** Do not import `@ember/component/input`. For a checkbox, use native `<input type="checkbox">` + `{{on "change" ...}}` from `@ember/modifier`, or `import { Input } from "@ember/component"` (named) if you need Ember Input.

Browser console check after deploy:

```js
Object.keys(requirejs.entries).filter(k => k.includes("youtrack"))
// expect connector and initializer under discourse/plugins/discourse-youtrack/...
document.querySelector(".discourse-youtrack-sync")
```

**Context.** Connector: `discourse-youtrack-sync.gjs`. Related: ERR-002 (outlet path), ERR-003 (partial precompile).
