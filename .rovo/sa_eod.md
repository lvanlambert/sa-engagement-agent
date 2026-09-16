# SA End-of-Day Engagement Sync

Load and follow the **`sa-engagement-logger`** skill (`get_skill("sa-engagement-logger")`), then execute an end-of-day engagement sync for the current user.

Arguments (optional, parse from the invocation):
- `--since <window>` — lookback window (e.g. `3d`, `1w`). Default: since last successful run (or today if no state).
- `--customer <domain>` — restrict to a single customer domain.
- `--dry-run` — do everything up to drafting, but do not create/update any pages; show what would happen.

Follow the skill's full workflow: connector pre-flight → scan calendar → identify customer(s) via SAREQ → resolve pages → enrich → detect co-delivery → draft in Hello personal space → Slack ping → await approval → promote on approval. Always respect the approval gate before writing to Account Central.
