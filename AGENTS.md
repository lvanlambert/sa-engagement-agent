# Team Conventions — SA Engagement Logger

Shared constants for the `sa-engagement-logger` skill. These are team-wide facts, not
per-person config. Do not put individual identities, tokens, or customer-specific values here.

## Atlassian sites
- **Account Central (internal):** `hello` (`hello.atlassian.net`). AC pages, SAREQ, and draft
  staging (personal spaces) all live here.
- **Customer-facing content:** `as-a-team` (`as-a-team.atlassian.net`). Per-customer spaces
  hold deliverables shared with / co-worked with customers. **Never stage internal drafts here.**
- The two sites are in the same TWG org; cross-site smart links + `twg resolve` work.

## SAREQ project (source of truth for engagements)
- Project key: **SAREQ** (JSM service desk) on `hello`.
- Index query: `project = SAREQ AND assignee = currentUser()`.
- Custom field IDs (verified; require TWG CLI ≥ 1.2.8 to hydrate values):
  - `customfield_72013` — **Salesforce Opportunity Link** (required, smart link).
  - `customfield_100945` — **Account Slack Channel** (required; may/may not have leading `#` — normalize).
  - `customfield_72066` — **Region** (multi-option; read `.value`).
  - `customfield_72065` — **Deal Close Date** (synced from Salesforce).

## Account Central page naming
- Customer hub: `<domain>` (e.g. `medtronic.com`).
- Role page family under the hub: `<domain> Solution Architects`, `<domain> Field CTO`,
  `<domain> Value Management Office`, `<domain> Solution Engineer`.
- **This agent targets `<domain> Solution Architects` only.** Space key: `ACStrategic`.
- Each SA page has an **Engagement Log** (table: Date/Session/Attendees · Notes · Next Steps)
  and an **Asset Repository** (link assets shared with the customer, dated).

## Team model
- "My team" = current user → manager (`twg user get`) → `twg org-tree --email <manager>
  --depth 2+`, traversing the **full sub-tree** (co-deliverers may be under a different
  sub-manager). Derive at runtime; never hardcode.

## Asset & content rules (summary — see docs/DESIGN.md for full)
- Asset Repository = **authored deliverables only**, grouped by **month** in collapsible
  expands, inline smart links. Exclude Loom recordings (→ log row) and meeting-notes pages.
- SAREQ ticket + Salesforce opp are referenced once via the page template — do NOT re-link per meeting.
- Content follows the **SA lens** (commercial detail only if it shapes architecture).

## Connectors
- Atlassian/TWG: automatic per-user (Rovo login).
- Google Calendar, Loom, Slack: per-user one-time OAuth. Slack's 3LO grant is currently
  flaky org-wide — the agent degrades gracefully without it. See docs/ONBOARDING.md.
