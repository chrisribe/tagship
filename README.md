# Tagship

> Tag it. Ship it. No SSH required.

## Overview
Tag-triggered deploy pipeline for Docker services on Hetzner VPS.

## Server Setup
- VPS with 2GB RAM
- Multiple subdomains via Nginx Proxy Manager (NPM)
- Each subdomain is an independent Docker container running Node.js/Express + PostgreSQL
- Container management via Dockge (may be replaced)
- Infrastructure: Cloudflare DNS → NPM → Docker containers

## Goal
Replace manual `git pull && docker compose up --build` with a tag-triggered automated deploy pipeline.

## Chosen Solution: GitHub Actions + Webhook Listener

### Trigger
- Developer pushes a semver tag to main (e.g. `git tag v1.0.3 && git push --tags`)
- Each service is its own GitHub repo
- Tagging any repo triggers deploy of only that service

### Flow
```
git tag v1.2.0 && git push --tags
  → GitHub Actions fires (deploy.yml)
  → GHA sends POST to https://deploy.pixagreat.com/hooks/deploy
       with Bearer token + JSON payload {repo, tag}
  → Webhook container (almir/webhook) receives request
  → Validates Bearer token
  → Executes deploy.sh with repo and tag as args
  → deploy.sh: git checkout tags/<tag> && docker compose up --build -d
```

### Components

**`.github/workflows/deploy.yml`** (lives in each service repo)
- Triggers on `v*` tag push
- Sends authenticated POST to webhook endpoint
- Passes `github.repository` and `github.ref_name` (the tag) as payload

**`hooks.json`** (webhook listener config)
- Defines the `/hooks/deploy` endpoint
- Validates `Authorization: Bearer <token>` header
- Maps to `deploy.sh` and passes `repo` + `tag` as args

**`deploy.sh`** (server-side deploy logic)
- Receives repo name and tag as $1/$2
- Maintains a hardcoded map of `repo → server path`
- `cd`s to the correct app directory, checks out the tag, rebuilds

**`docker-compose.webhook.yml`** (webhook listener service)
- Image: `almir/webhook`
- Exposed on port 9000, proxied via NPM at `deploy.yourdomain.com`
- Mounts: `hooks.json`, `deploy.sh`, `/var/run/docker.sock`, `/srv/apps`

### Auth
- Single shared `DEPLOY_TOKEN` (random string)
- Stored as GitHub Actions secret per repo
- Hardcoded in `hooks.json` for validation (or use env var)

### Per-Repo Setup

For each repo you want to auto-deploy:

1. **Copy workflow file:**
   ```bash
   mkdir -p .github/workflows
   cp /opt/stacks/tagship/deploy.yml .github/workflows/deploy.yml
   git add .github/workflows/deploy.yml
   git commit -m "Add tagship deploy workflow"
   git push
   ```

2. **Add secret in GitHub:**
   - Repo → Settings → Secrets and variables → Actions → New repository secret
   - Name: `DEPLOY_TOKEN`
   - Value: (same token as in hooks.json)

3. **Add repo to deploy.sh:**
   ```bash
   # Edit /opt/stacks/tagship/scripts/deploy.sh
   # Add entry to REPO_PATHS:
   ["chrisribe/your-repo"]="/opt/stacks/your-repo"
   ```

4. **Clone repo on server** (if not already):
   ```bash
   cd /opt/stacks
   git clone git@github.com:chrisribe/your-repo.git
   ```

5. **Deploy:**
   ```bash
   git tag v1.0.0 && git push --tags
   ```

### NPM Config
- Proxy host: `deploy.pixagreat.com` → `tagship:9000`
- SSL enabled as normal

## What's Not Handled (known gaps)
- No rollback automation (manual `git checkout <prev-tag>` + rebuild)
- No deploy notifications (Slack, email, etc.)
- No health check post-deploy
- Shared `DEPLOY_TOKEN` across all repos (acceptable for solo/small team)
- `deploy.sh` runs as the webhook container user — needs docker socket access and write permissions on `/srv/apps`