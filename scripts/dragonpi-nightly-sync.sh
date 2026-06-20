#!/bin/bash
set -e

REPO_DIR="/opt/dragonpi"
LOG="/var/log/dragonpi-nightly-sync.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] DragonPi Nightly Sync — starting" | tee -a "$LOG"
cd "$REPO_DIR"

AHEAD=$(git rev-list --count origin/main..main 2>/dev/null || echo 0)
DIRTY=$(git status --porcelain)
if [ -z "$DIRTY" ] && [ "$AHEAD" -eq 0 ]; then
    echo "[$DATE]  Nothing to push — repo clean and up to date" | tee -a "$LOG"
    exit 0
fi

# ── Secret leak check ──
SECRET_LEAK=0
for sf in secrets.md AGENTS.md; do
    if ! git check-ignore "$sf" >/dev/null 2>&1; then
        echo "[$DATE]  ❌ $sf is NOT gitignored — aborting!" | tee -a "$LOG"; SECRET_LEAK=1
    fi
done
if [ -f "secrets.md" ]; then
    PWD_VAL=$(grep -iP '^\|.*password' secrets.md | grep -v '^#' | awk -F'|' '{print $3}' | head -1 | xargs)
    if [ -n "$PWD_VAL" ] && git grep -nF "$PWD_VAL" -- ':!*.gitignore' ':!scripts/dragonpi-update' ':!scripts/dragonpi-nightly-sync.sh' >/dev/null 2>&1; then
        echo "[$DATE]  ❌ CREDENTIALS FOUND in tracked files — aborting!" | tee -a "$LOG"; SECRET_LEAK=1
    fi
fi
if [ "$SECRET_LEAK" -ne 0 ]; then
    echo "[$DATE]  🛑 Sync aborted — fix secrets first" | tee -a "$LOG"; exit 1
fi

# ── Check for API tokens in uncommitted changes ──
TOKEN_RE="ghp_[A-Za-z0-9]{36}|sk-[A-Za-z0-9]{20,}"
LEAKED=$( { git diff --cached 2>/dev/null; git diff 2>/dev/null; } | grep -E "^\+" | grep -oE "$TOKEN_RE" | head -5)
if [ -n "$LEAKED" ]; then
    echo "[$DATE]  ❌ API tokens detected in uncommitted changes — aborting!" | tee -a "$LOG"
    echo "  $LEAKED" | tee -a "$LOG"; exit 1
fi

# ── Stage and commit ──
if [ -n "$DIRTY" ]; then
    git add -A
    STAGED=$(git diff --cached | grep -E "^\+" | grep -oE "$TOKEN_RE" | head -5)
    if [ -n "$STAGED" ]; then
        echo "[$DATE]  ❌ Tokens found in staged diff — rolling back!" | tee -a "$LOG"
        git reset HEAD . 2>/dev/null; exit 1
    fi
    COMMIT_MSG="nightly sync: $(date '+%Y-%m-%d %H:%M')"
    git commit -m "$COMMIT_MSG"
    echo "[$DATE]  Committed: $COMMIT_MSG" | tee -a "$LOG"
fi

# ── Push ──
if [ "$(git rev-list --count origin/main..main 2>/dev/null || echo 0)" -gt 0 ]; then
    echo "[$DATE]  Pushing to origin/main..." | tee -a "$LOG"
    git push origin main 2>&1 | tee -a "$LOG"
    echo "[$DATE] ✅ Nightly sync complete" | tee -a "$LOG"
else
    echo "[$DATE]  Nothing to push" | tee -a "$LOG"
fi
