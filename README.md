# SA Engagement Logger (Rovo CLI Agent)

An identity-driven Rovo CLI agent that, on an end-of-day run, finds your customer meetings, gathers context across your work tools, and produces an **approval-gated** Engagement Log update + curated asset links on the customer's **Account Central "[domain] Solution Architects"** page.

It runs as **you** — using your own Atlassian/TWG access and your own connected Calendar/Loom/Slack — so the whole SA team can use the same agent without per-person configuration beyond a one-time connector authorization.

## What it does (per run)
1. Scans your calendar for customer meetings (since your last run).
2. Identifies the customer from your **SAREQ** tickets (`assignee = currentUser()`).
3. Locates the customer's **as-a-team** space + **Account Central** SA page.
4. Enriches from Loom (transcript/recap/action items), Slack (`#acct-<customer>` + DMs), meeting notes, and authored deliverables.
5. Detects **co-delivery teammates** (calendar attendees who are on your team sub-tree) and attributes their content too.
6. Drafts an engagement page in **your Hello personal space** (staging) — never writes to Account Central without approval.
7. Pings you in Slack with the draft link.
8. On your approval, **promotes** the Engagement Log row + monthly asset smart links to the AC page.

## Quick start
```bash
# 1. Install the skill globally (works in any workspace)
bash install.sh

# 2. In Rovo CLI, run the end-of-day sync
/prompts sa-eod
# or a custom window / single customer:
/prompts sa-eod --since 3d
/prompts sa-eod --customer medtronic.com
```

## Onboarding (per teammate, one-time)
See [`docs/ONBOARDING.md`](docs/ONBOARDING.md). Summary:
1. Clone this repo, run `install.sh`.
2. Install + log into Rovo CLI (Atlassian/TWG auth is automatic).
3. Authorize **Google Calendar** and **Loom** connectors (one-time OAuth).
4. Authorize **Slack** when available (its 3LO grant is currently flaky org-wide — see onboarding notes; the agent degrades gracefully without it).

## How it stays team-scalable
- **No hardcoded identity.** Uses `assignee = currentUser()`, `twg user get`, `twg org-tree`, and `twg confluence space me` to derive *your* customers, *your* team, and *your* draft space at runtime.
- **Shared logic, per-user execution.** Everyone loads the same `SKILL.md`; it runs under each person's credentials.
- **Conventions live in `AGENTS.md`** (site names, SAREQ field IDs, AC naming), not in per-person config.

## Docs
- [`docs/DESIGN.md`](docs/DESIGN.md) — full design spec (source of truth for behavior).
- [`docs/ONBOARDING.md`](docs/ONBOARDING.md) — setup + connector re-auth.
- [`.rovo/skills/sa-engagement-logger/SKILL.md`](.rovo/skills/sa-engagement-logger/SKILL.md) — the agent logic.

## Roadmap
- **v1 (now):** Skill + prompt, human-in-the-loop, approval-gated.
- **Later:** graduate to a dedicated **subagent** for unattended/scheduled EOD batch runs with tight tool guardrails. The current `SKILL.md` becomes the subagent's system prompt (clean upgrade, no rework).
- Role forks (SE/AE/VMO) reusing the same engine.
