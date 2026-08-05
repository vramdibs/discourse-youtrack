# discourse-youtrack

Discourse plugin: bridge topics/posts with YouTrack issues.

## Features (v0.2)

- Pingback Discourse → YouTrack: checkbox in reply composer sends post as issue comment (opt-in per reply)
- Soft-delete of a synced Discourse post deletes the linked YouTrack comment
- Pingback comments carry a marker so YouTrack→email→Discourse echo is discarded
- Issue link parsed from post #1 (email from YouTrack); id cached on topic custom field
- YouTrack → Discourse unchanged (incoming email), except pingback echoes

## Layout

- `plugin.rb` - custom fields, serializers, post hooks
- `lib/discourse_youtrack/` - resolver, formatter, REST client, pingback marker, email echo filter
- `app/jobs/regular/sync_post_to_youtrack.rb` - Sidekiq job (create comment)
- `app/jobs/regular/delete_youtrack_comment.rb` - Sidekiq job (delete comment on soft-delete)
- `assets/javascripts/` - composer checkbox, error notice via MessageBus
- `config/settings.yml` - enable flag, base URL, API token (secret)

## Site settings

| Setting | Purpose |
|---------|---------|
| `discourse_youtrack_enabled` | Master switch |
| `discourse_youtrack_base_url` | e.g. `https://youtrack.example.com` |
| `discourse_youtrack_api_token` | Permanent token (Bearer), secret |

## Manual smoke

1. Enable plugin and set URL + token in Admin → Settings → Plugins
2. Open a topic whose first post links to a YouTrack issue (email bot post)
3. Reply with checkbox «Add comment to YouTrack» checked
4. Confirm comment in YouTrack with header, text, and Discourse link
5. Reply without checkbox — no new YT comment

## Ops notes

Plugin jobs must live under `app/jobs/regular/`, not `jobs/regular/`. After JS changes in `assets/javascripts/`, run a full `assets:precompile` without `SKIP_EMBER_CLI_COMPILE=1`.

See [docs/errors_registry.md](docs/errors_registry.md) for common deployment traps.

## Secrets

Use Discourse site settings for the API token. Do not commit tokens.
