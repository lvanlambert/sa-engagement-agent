# SA Engagement Logger — Design Spec (v1)

_Locked decisions from design Q&A. This is the source of truth for building the distributable Rovo CLI agent package._

## Purpose
An identity-driven Rovo CLI agent that, on an EOD run, finds a Solution Architect's customer meetings, gathers context across sources, and produces an approval-gated **Engagement Log** update + curated asset smart links on the customer's **Account Central (AC) "[domain] Solution Architects"** page.

## Scope (v1)
- **SA pages only.** Targets `[domain] Solution Architects` in `ACStrategic` on the `hello` site. Designed to be **forked per role/team** later — not one agent for all roles.
- **Identity-driven & team-scalable.** Runs as whoever invokes it (Atlassian/TWG auth is per-user automatic). Third-party connectors (Calendar, Slack, Loom) are per-user one-time OAuth.

## Sources of truth
- **SAREQ (JSM, `hello`)** = primary index of engagements. `project = SAREQ AND assignee = currentUser()`.
  - Field IDs: `customfield_72013` = Salesforce Opportunity Link (required smart link), `customfield_100945` = Account Slack Channel (normalize leading `#`), `customfield_72066` = Region (array → `.value`), `customfield_72065` = Deal Close Date.
  - Requires TWG CLI ≥ 1.2.8 to hydrate custom-field values (`get --fields "customfield_..."`).
- **Google Calendar** = precise meeting date + full attendee list (internal + customer).
- **Loom** = transcript / AI recap / action items (only videos owned by or shared with the runner).
- **as-a-team Confluence** = customer deliverables/content (per-customer spaces, e.g. `SALE` = Salesforce).
- **Slack** = qualitative context (channel `#acct-<customer>` + DMs).
- **Auto meeting-notes pages** (Loom/Calendar-generated) = smart-linked as source, not duplicated.

## Core flow (EOD run)
1. **Connector pre-flight health check** — 3-state per connector: authed / `MCP_UNAUTHENTICATED` (tell user to re-auth) / disabled=`Unknown tool` (tell user to enable). Degrade gracefully (SAREQ + as-a-team can carry a run if Slack/Calendar are down).
2. **Determine window** = since last successful run (state file with last-run timestamp). Manual lookback override allowed.
3. **Scan Calendar** for meetings in window.
4. **Identify customer meetings**: external (non-Atlassian) attendee whose domain maps to one of the runner's SAREQ tickets. **SAREQ-preferred; if external attendee but no SAREQ, still process and FLAG for review.**
5. **Resolve customer → pages**: as-a-team space + AC `[domain] Solution Architects` page. If SA page missing/ambiguous, ask.
6. **Team roster & co-delivery**: current user → manager via `twg`, expand **full sub-tree (depth ≥ 2, configurable)**. Attendees ∩ team sub-tree = co-deliverers. Attribute content **created OR updated by anyone on the team** (not just the runner).
7. **Enrich**: synthesize from ALL available sources, cite each with smart links. (Loom transcript/recap, Slack thread/DM context, notes page, deliverable.)
8. **Draft** one page **per customer per meeting/run** in the runner's **Hello personal Confluence space** (staging — on `hello`, NOT as-a-team, since as-a-team is customer-facing and AC pages/review live on Hello).
9. **Notify** via Slack DM: link to today's draft page(s) + one-line summary each.
10. **Approve in Slack** (reply e.g. `approve salesforce`). User may edit draft pages first, then approve.
11. **Promote on approval** → structured write to the AC SA page (see Promotion mechanics).
12. **SAREQ cross-link**: ASK per run whether to add a comment on the SAREQ ticket linking the AC update. (No SAREQ writes without opt-in.)
13. **Run report** trail: draft lives in personal space; on approval content moves to AC.

## Content policy — SA lens
- Include meeting substance relevant to **SA scope of work**.
- **Include cross-role/commercial detail ONLY when it materially affects SA architecture/design.**
  - Example: an AE's CMK (paid add-on) pitch whose customer response changes the architecture the SA is designing → include as an "architecture-relevant" note.
  - Pure commercial / SE / AE updates that don't touch SA work → belong on THAT role's AC page, not the SA page.
- Redact nothing that's SA-relevant; don't import other roles' scope wholesale.

## Draft page structure (Hello personal space, staging)
- Title: `DRAFT — Engagement Update: <domain> (SA) — <session> — <date>`
- Hidden marker (HTML comment): `rovo-meeting-id`, `customer`, `run-date` (dedup key).
- Reviewer note w/ Slack approval instructions.
- **Engagement Log row** (copied VERBATIM into AC on approval).
- **Asset links** (become smart links in AC, grouped by month — see below).
- **Context (SAREQ)** section = review-only, NOT written to AC.

## Promotion mechanics (draft → AC on approval)
| Draft element | Action on AC page |
|---|---|
| Engagement Log row | **Copied verbatim** — prepended to the AC Engagement Log table (newest on top). Inline smart links inside the row. **Loom recording for the meeting goes IN THIS ROW** (not the Asset Repository). |
| Asset links | Added to **Asset Repository**, **grouped by month in collapsible expands** (see below). Inline smart links (not block cards) to stay compact. **Only evidence-based shared deliverables** — see Asset detection. |
| Context (SAREQ) | **Dropped** (review-only). |
| Reviewer note / staging cruft | **Dropped**. Hidden `rovo-meeting-id` marker rides into the AC row for dedup. |

### What does NOT go in the per-meeting Asset Repository (avoid bloat / repetition)
- **Loom recordings** → live in the **Engagement Log row** for that meeting instead.
- **SAREQ ticket link** → referenced ONCE on the page via template creation; do not re-link per meeting.
- **Salesforce opportunity link** → mentioned ONCE on the page (template-level); do not re-link per meeting.

## Asset detection (evidence-based, not "newest in space")
The agent must **deduce exactly which asset(s) were shared/discussed in THAT meeting** by reasoning across all meeting signals — NOT by grabbing the most-recently-modified page in the customer's space (that will link wrong content once a space is active).

Signals to corroborate an asset ↔ meeting match:
- **Calendar invite title / agenda** → topic keywords (e.g. "SDA", "migration").
- **Loom transcript** → explicit doc references, screen-shares, spoken titles, "I'll share the…".
- **Slack** (`#acct-<customer>` + DMs around meeting time) → links pasted or docs named.
- **Meeting-notes page** → linked/attached materials.
- **Team attribution** → asset created OR updated by anyone on the runner's team sub-tree.

Rules:
- **List candidates for the approver.** Present a short **ranked candidate list** in the draft (with the signal that matched each); the approver picks which to keep before promotion. Precision over recall — it's fine to under-link and let the approver add.
- **No confident match → state "no assets detected"** in the draft so the approver knows to add one if needed. Do not silently guess.
- **Asset scope (v1):** as-a-team Confluence deliverables **+ Google Drive/Docs** files referenced via Loom/Slack/calendar. (Broader external artifacts are future scope.)

### What qualifies as an Asset (the bar)
The Asset Repository is a **deliverables library for internal reuse**, not a log of everything shared. Two different purposes:
- **Engagement Log row** = the *narrative* of the meeting (includes the **Loom recording** as evidence).
- **Asset Repository** = **substantive, authored work product** the team *created and worked on WITH the customer* — SDAs, architecture docs, whiteboards, decks, migration/assessment docs.

**Assets = authored deliverables ONLY. Explicitly excluded:**
- **Loom recordings** → live in the Engagement Log row, never in assets.
- **Auto-generated meeting-notes pages** (Loom-recap pages) → **not linked at all** (redundant with the recording link already in the row). They may still be *read* as a signal for asset detection, but are not themselves promoted.
- Anything that is evidence/record of a conversation rather than a reusable work product.

Rationale: the recording is already one click away in the log row; internal teams want the *deliverables* to reuse/build on, so the monthly asset expands stay a curated shelf, not a dumping ground.

### Missing-deliverable reminder (NO Hello search in v1)
as-a-team is where customer-facing deliverables belong (so customers can co-work/keep them). Teams sometimes build a page in Hello and forget to publish it to as-a-team. We handle this as a **reminder, not a search** — deliberately avoiding broad Hello content search (scope creep + risk of surfacing internal-only pages as customer assets).

- **Behavior:** when a **likely-deliverable session** (calendar title / Loom content indicates workshop / design / SDA / review — NOT a casual check-in) has **no authored as-a-team deliverable detected**, add a gentle flag in the draft:
  > ⚠️ This looked like a working/deliverable session, but no as-a-team deliverable was detected. If you produced a page/deck/whiteboard, add it to as-a-team (so the customer can co-work/keep it), then paste the link here.
- **Dual purpose:** nudges the SA to publish to as-a-team (right behavior) AND leaves a clean manual-link path for the approver.
- **No automatic Hello search.** Keeps as-a-team the single trustworthy source of customer deliverables; never surfaces internal-only Hello pages as customer assets.
- **Trigger is type-gated:** only fire on likely-deliverable sessions to stay high-signal (don't nag on every sync).
- **Future (opt-in only):** if the nudge proves insufficient, add a NARROW lookup limited to the SA's OWN recently-authored Hello pages (not open Hello search) as flagged suggestions.

## Asset Repository layout (blend of E + C)
- Assets grouped by **month**, each month in a **collapsible expand** (collapsed by default) so the page never gets crazy long.
- Inside each month expand: inline smart links to that month's **authored deliverables only** (as-a-team pages, whiteboards, decks, docs). No recordings or notes pages.
- Engagement Log table remains the chronological narrative; each row also carries its own meeting's inline smart links.
- Node count bounded (12 expands/yr/customer); no per-run explosion.

## Write safety & idempotency
- **Draft → approve → write** (no autonomous AC writes in v1).
- **Dedup**: primary key = hidden `rovo-meeting-id` in AC row; fallback = date + session name. Skip if present.
- **Never overwrite**: only PREPEND rows / ADD links. Never rewrite existing log content.
- Fetch fresh HTML + snapshot token before any AC edit; minimal targeted edits.

## Smart-link vs. content strategy (from earlier validation)
- Smart links / embeds render live cross-site and are **agent-traversable** (agent can follow a link and fetch the target body), but do **NOT** create a graph edge or index content on `hello`.
- Therefore: **live smart-link the artifacts + write a short native summary** (the Engagement Log row) so the gist is natively searchable on `hello`.
- Cross-site links (`as-a-team` ↔ `hello`) confirmed working (same TWG org; `twg resolve` returns ARIs).

## Team attribution rules
- "My team" = current user's manager's full sub-tree (`twg org-tree --email <manager> --depth N`, N configurable ≥ 2). Traverse sub-tree, not just direct peers (a co-deliverer may be under a different sub-manager, e.g. Tanya Gordon under Brad Bressler).
- Resolve Confluence version-history **account IDs** → people via `twg user get --account-id`, then check team membership.
- Inaccessible teammate Looms: **note the gap**, enrich from other sources.

## Packaging & rollout
- Distributable assets in a shared repo: `.rovo/skills/` (SKILL.md), `.rovo/prompts.yml` (entry-point prompt), `AGENTS.md` (team conventions).
- Per-user onboarding: (1) install + log into Rovo CLI (Atlassian/TWG done), (2) authorize Google Calendar, (3) authorize Loom, (4) authorize Slack. One-time OAuth each; set-and-forget (auto-refresh) barring revocation.
- Connector auth note: managed/brokered server-side; creds in macOS Keychain (`rovo-oauth`, `Rovo Safe Storage`), not a local `mcp.json`. Re-auth = full CLI sign-out/in if a connector goes `MCP_UNAUTHENTICATED`.

## Open items / future
- Fork templates for SE / AE / VMO roles.
- Escape hatch for very active accounts: split Asset Repository by major workstream into a few child pages (human-decided, not automatic).
- Confirm reliable Slack channel-name normalization across tickets.
