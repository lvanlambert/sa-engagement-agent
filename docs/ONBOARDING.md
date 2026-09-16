# Onboarding — SA Engagement Logger

One-time setup per teammate. After this, the daily flow is just `/prompts sa-eod`.

## 1. Install the skill
```bash
git clone <repo-url> sa-engagement-agent
cd sa-engagement-agent
bash install.sh          # copies skill + prompt into ~/.rovo so it works in any workspace
```
`install.sh` copies:
- `.rovo/skills/sa-engagement-logger/` → `~/.rovo/skills/sa-engagement-logger/`
- `.rovo/prompts.yml` + `.rovo/sa_eod.md` → merged into `~/.rovo/`
- `AGENTS.md` guidance is picked up when you run inside the repo, or copy relevant bits to `~/.rovo/AGENTS.md`.

## 2. Rovo CLI + Atlassian/TWG (automatic)
- Install Rovo CLI and log in. This authenticates **you** across your Atlassian sites and TWG.
- Ensure TWG CLI is **≥ 1.2.8** (`twg --version`; `twg update` to upgrade) — required to read
  SAREQ custom-field values.
- No tokens to configure — Jira/Confluence/Bitbucket/TWG all run as you.

## 3. Connect Calendar + Loom (one-time OAuth)
In Rovo CLI, open `/mcp` and ensure **Google Calendar** and **Loom** are enabled and authorized.
First use triggers a browser consent. These are set-and-forget (auto-refresh) barring revocation.

## 4. Slack (when available)
Slack's third-party (3LO) grant has been intermittently failing org-wide
(`MCP_UNAUTHENTICATED: Access token is required for ExternalThreeLegged action execution`).
- The agent **degrades gracefully** without Slack (uses SAREQ + Calendar + Loom + as-a-team).
- When it works, Slack adds valuable qualitative context and enables the approval-DM step.

### If a connector returns `MCP_UNAUTHENTICATED`
Observed behavior + fixes (in order):
1. `/mcp` → confirm the connector is enabled (re-enable if needed; changes may need a session restart).
2. Fully **quit and relaunch** Rovo CLI (forces a fresh token mint on next call).
3. `rovo mcp clear-auth` — note: for brokered connectors this may report *"No MCP OAuth
   credentials found"* because creds live in the **macOS Keychain** (`rovo-oauth`,
   `Rovo Safe Storage`), not a local file.
4. If it persists: it's likely a **server-side / Keychain↔backend session mismatch** or an
   org-admin grant issue — raise it in the Rovo CLI support channel. (`clear-auth` empty +
   server `MCP_UNAUTHENTICATED` = that mismatch signature.)

## 5. Daily use
```bash
/prompts sa-eod                 # since your last run
/prompts sa-eod --since 3d      # custom window
/prompts sa-eod --customer medtronic.com
/prompts sa-eod --dry-run       # draft nothing; just show what would happen
```
Review the draft in your Hello personal space, edit if needed, then approve to promote to the
Account Central SA page.

## Troubleshooting
- **No customers found:** check you have SAREQ tickets assigned (`assignee = currentUser()`).
- **Custom fields empty:** upgrade TWG CLI to ≥ 1.2.8.
- **Wrong AC page:** the agent asks if the SA page is ambiguous; confirm the `<domain> Solution Architects` page.
- **Xcode license prompt** on macOS can intercept `python3` in scripts — run `sudo xcodebuild -license accept` once (unrelated to Rovo).
