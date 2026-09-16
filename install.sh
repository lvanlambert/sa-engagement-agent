#!/usr/bin/env bash
# Installs the SA Engagement Logger skill + prompt into ~/.rovo so it works in any workspace.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROVO_HOME="${ROVO_HOME:-$HOME/.rovo}"

echo "Installing SA Engagement Logger into $ROVO_HOME ..."

# 1. Skill
mkdir -p "$ROVO_HOME/skills/sa-engagement-logger"
cp -R "$REPO_DIR/.rovo/skills/sa-engagement-logger/." "$ROVO_HOME/skills/sa-engagement-logger/"
echo "  ✓ skill -> $ROVO_HOME/skills/sa-engagement-logger/"

# 2. Prompt content file
cp "$REPO_DIR/.rovo/sa_eod.md" "$ROVO_HOME/sa_eod.md"
echo "  ✓ prompt content -> $ROVO_HOME/sa_eod.md"

# 3. Merge the prompt entry into ~/.rovo/prompts.yml (create if missing; append if not present)
PROMPTS="$ROVO_HOME/prompts.yml"
if [ ! -f "$PROMPTS" ]; then
  cp "$REPO_DIR/.rovo/prompts.yml" "$PROMPTS"
  echo "  ✓ created $PROMPTS"
elif grep -q "name: sa-eod" "$PROMPTS"; then
  echo "  = sa-eod prompt already present in $PROMPTS (leaving as-is)"
else
  # append the sa-eod block (skip the leading 'prompts:' line from the repo copy)
  tail -n +2 "$REPO_DIR/.rovo/prompts.yml" >> "$PROMPTS"
  echo "  ✓ appended sa-eod prompt to $PROMPTS"
fi

cat <<'DONE'

Done. Next steps:
  1. Ensure TWG CLI >= 1.2.8:            twg --version   (twg update to upgrade)
  2. In Rovo CLI, authorize connectors:  /mcp  (Google Calendar, Loom, Slack)
  3. Run it:                             /prompts sa-eod

See docs/ONBOARDING.md for details.
DONE
