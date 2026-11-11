#!/usr/bin/env bash
# Run from the repository root BEFORE every push to a public repository.
# Usage: bash scripts/check-secrets.sh
# Exit code 1 means something suspicious was found: fix it, do not push.
#
# This file is committed, so it contains only generic credential patterns.
# Anything specific to this deployment - project identifiers, bucket names,
# invite-code formats, payment providers, phrases from licensed material -
# belongs in scripts/check-secrets.local, which is gitignored. Naming those
# strings in a committed file would publish the very things the check exists
# to keep out.

set -u

# Generic credential shapes. Safe to publish: they identify no one.
PATTERNS='sk-ant|sk-[A-Za-z0-9]{32,}|service_role|SUPABASE_SERVICE|eyJ[A-Za-z0-9_-]{20,}|re_[A-Za-z0-9]{20,}|RESEND|SMTP_PASS|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}'

LOCAL_PATTERNS_FILE="scripts/check-secrets.local"
if [ -f "$LOCAL_PATTERNS_FILE" ]; then
  EXTRA=$(grep -vE '^\s*(#|$)' "$LOCAL_PATTERNS_FILE" | paste -sd '|' -)
  if [ -n "$EXTRA" ]; then
    PATTERNS="$PATTERNS|$EXTRA"
    echo "Loaded $(grep -cvE '^\s*(#|$)' "$LOCAL_PATTERNS_FILE") extra pattern(s) from $LOCAL_PATTERNS_FILE"
  fi
else
  echo "NOTE: $LOCAL_PATTERNS_FILE not found."
  echo "      Deployment-specific strings are NOT being checked. See the header of this file."
fi

FOUND=0

echo
echo "== 1. Current files =="
if grep -rIniE "$PATTERNS" . --exclude-dir=.git --exclude-dir=node_modules \
     --exclude=check-secrets.sh --exclude=check-secrets.local; then FOUND=1; fi

echo
echo "== 2. Git history (all commits) =="
if git rev-parse --git-dir >/dev/null 2>&1; then
  if git log -p --all | grep -niE "$PATTERNS" | head -50; then FOUND=1; fi
fi

echo
echo "== 3. Dedicated scanner (if installed) =="
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --source . --verbose || FOUND=1
else
  echo "gitleaks not installed. Strongly recommended: https://github.com/gitleaks/gitleaks"
fi

echo
echo "== 4. Author identity =="
if git rev-parse --git-dir >/dev/null 2>&1; then
  if git log --format='%ae' --all 2>/dev/null | sort -u | grep -v 'users.noreply.github.com'; then
    echo "  ^ commits carry a real address. Set a noreply address before making this public."
    FOUND=1
  else
    echo "no real email addresses in commit history"
  fi
fi

echo
if [ "$FOUND" -eq 1 ]; then
  echo "RESULT: matches found. Review every line above. Do NOT push."
  exit 1
fi
echo "RESULT: no matches. Still read the file list once with: git ls-files"
