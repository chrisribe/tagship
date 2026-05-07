#!/bin/bash
# Tagship — one-command installer
# Usage: curl -sL https://raw.githubusercontent.com/chrisribe/tagship/main/install.sh | bash
set -e

INSTALL_DIR="/opt/stacks/tagship"
DEPLOY_TOKEN=$(openssl rand -hex 32)

echo ""
echo "⚓ Tagship Installer"
echo "════════════════════"
echo ""

# 1. Clone
if [ -d "$INSTALL_DIR" ]; then
  echo "📂 Already installed at $INSTALL_DIR — pulling latest..."
  cd "$INSTALL_DIR" && git pull
else
  echo "📥 Cloning to $INSTALL_DIR..."
  git clone https://github.com/chrisribe/tagship.git "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# 2. Generate deploy token
if [ -f "$INSTALL_DIR/.env" ]; then
  echo "🔑 .env exists — skipping token generation"
  DEPLOY_TOKEN=$(grep DEPLOY_TOKEN "$INSTALL_DIR/.env" | cut -d= -f2)
else
  echo "DEPLOY_TOKEN=$DEPLOY_TOKEN" > "$INSTALL_DIR/.env"
  chmod 600 "$INSTALL_DIR/.env"
  echo "🔑 Generated deploy token → .env"
fi

# 3. Setup SSH key
if [ ! -f "$HOME/.ssh/id_deploy" ]; then
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_deploy" -N "" -C "tagship@$(hostname)" -q
  grep -q "github.com" "$HOME/.ssh/known_hosts" 2>/dev/null || ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
  echo "🔐 Created SSH deploy key"
else
  echo "🔐 SSH key exists — skipping"
fi

# 4. Install CLI
chmod +x "$INSTALL_DIR/tagship"
ln -sf "$INSTALL_DIR/tagship" /usr/local/bin/tagship
echo "🛠️  CLI installed (tagship command)"

# 5. Start container
docker compose -f docker-compose.webhook.yml up -d --build
echo "🚀 Webhook container running"

# 5. Summary
echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ Tagship installed!"
echo ""
echo "1. Add this SSH key to GitHub (Settings → SSH keys):"
echo "────────────────────────────────────────────────────────────"
cat "$HOME/.ssh/id_deploy.pub"
echo ""
echo "────────────────────────────────────────────────────────────"
echo ""
echo "2. Your deploy token (add as DEPLOY_TOKEN secret per repo):"
echo "   $DEPLOY_TOKEN"
echo ""
echo "3. Add NPM proxy host:"
echo "   Domain: tagship.yourdomain.com → tagship:9000"
echo ""
echo "4. Add repos: tagship add <github-user/repo>"
echo ""
echo "Example:"
echo "   tagship add chrisribe/mood-tube"
echo "════════════════════════════════════════════════════════════"
