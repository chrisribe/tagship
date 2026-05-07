#!/bin/bash
# Setup server SSH key for GitHub
# One key, all repos, no config fuss

set -e

KEYFILE="$HOME/.ssh/id_deploy"

if [ -f "$KEYFILE" ]; then
  echo "Key exists: $KEYFILE"
else
  ssh-keygen -t ed25519 -f "$KEYFILE" -N "" -C "deploy@$(hostname)"
  echo "✅ Created: $KEYFILE"
fi

# Add GitHub host key if missing
grep -q "github.com" ~/.ssh/known_hosts 2>/dev/null || ssh-keyscan github.com >> ~/.ssh/known_hosts

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Add this key to GitHub → Settings → SSH and GPG keys → New:"
echo "───────────────────────────────────────────────────────────"
cat "${KEYFILE}.pub"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Then test with: ssh -i $KEYFILE -T git@github.com"
