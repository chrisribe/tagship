# Tagship

> Tag it. Ship it. No SSH required.

## Overview

KISS tag-triggered deploy pipeline for any Docker Compose service on any Linux VPS.

Push a semver tag → GitHub Actions fires → webhook on your server pulls the tag and rebuilds. No manual SSH needed for routine deploys.

## How It Works

```
git tag v1.2.0 && git push --tags
  → GitHub Actions fires (deploy.yml in your repo)
  → GHA sends POST to https://deploy.yourdomain.com/hooks/deploy
       with Bearer token + JSON payload {repo, tag}
  → Webhook container receives request, validates token
  → Executes deploy.sh with repo and tag as args
  → deploy.sh: git fetch → checkout tag → docker compose up --build -d
```

## Files

| File | Purpose |
|------|---------|
| `deploy.yml` | Copy to `.github/workflows/` in each repo you want to deploy |
| `docker-compose.webhook.yml` | Runs the webhook listener on your server |
| `webhook.dockerfile` | Adds git + docker CLI to the base webhook image |
| `hooks.json` | Webhook endpoint config + Bearer token auth |
| `scripts/deploy.sh` | Server-side deploy logic — maps repos to paths |
| `scripts/setup-deploy-key.sh` | One-time SSH key setup for git pull access |

## Server Setup (one-time)

**1. Clone tagship on your server:**
```bash
cd /opt/stacks   # or wherever you keep your apps
git clone git@github.com:yourusername/tagship.git
cd tagship
```

**2. Create deploy SSH key:**
```bash
./scripts/setup-deploy-key.sh
# Copy the displayed public key → GitHub → Settings → SSH keys → New
```

**3. Set your deploy token:**
```bash
# Generate a random token
openssl rand -hex 32

# Paste it into hooks.json, replacing YOUR_DEPLOY_TOKEN
# Include the "Bearer " prefix: "Bearer <your-token>"
nano hooks.json
```

**4. Add your repos to deploy.sh:**
```bash
nano scripts/deploy.sh
# Edit REPO_PATHS to map your repos to server paths:
# ["yourusername/your-repo"]="/opt/stacks/your-repo"
```

**5. Start the webhook container:**
```bash
docker compose -f docker-compose.webhook.yml up -d --build
```

**6. Add NPM proxy host:**
- Domain: `deploy.yourdomain.com`
- Forward to: `tagship:9000`
- SSL: enabled

## Per-Repo Setup

For each repo you want to auto-deploy:

**1. Add the workflow:**
```bash
mkdir -p .github/workflows
cp /opt/stacks/tagship/deploy.yml .github/workflows/deploy.yml
git add .github/workflows/deploy.yml
git commit -m "Add tagship deploy workflow"
git push
```

**2. Add GitHub secret:**
- Repo → Settings → Secrets and variables → Actions → New secret
- Name: `DEPLOY_TOKEN` — Value: (same token as in hooks.json)

**3. Clone repo on server** (if not already):
```bash
cd /opt/stacks
git clone git@github.com:yourusername/your-repo.git
```

**4. Deploy:**
```bash
git tag v1.0.0 && git push --tags
```

## Adding a New Repo Later

1. Clone it to your server under `/opt/stacks/`
2. Add an entry to `REPO_PATHS` in `scripts/deploy.sh`
3. Add `DEPLOY_TOKEN` secret to the repo on GitHub
4. Copy `deploy.yml` to `.github/workflows/` in the repo

## Known Gaps

- No rollback automation — manual: `git checkout <prev-tag> && docker compose up --build -d`
- No health check post-deploy
- No deploy notifications
- Single shared token across repos (fine for solo/small team)
