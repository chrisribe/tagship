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

```bash
curl -sL https://raw.githubusercontent.com/chrisribe/tagship/main/install.sh | bash
```

This will:
- Clone tagship to `/opt/stacks/tagship`
- Generate a deploy token
- Create an SSH deploy key
- Build and start the webhook container
- Install the `tagship` CLI

**After install, do these two manual steps:**

1. **Add SSH key to GitHub** — Copy the key displayed by the installer →
   GitHub → Settings → SSH and GPG keys → New SSH key

2. **Add NPM proxy host:**
   - Domain: `tagship.yourdomain.com`
   - Forward to: `tagship:9000`
   - SSL: enabled

## Per-Repo Setup

For each repo you want to auto-deploy:

**Step 1 — Add the workflow file (on your dev machine):**
```bash
cd your-repo
mkdir -p .github/workflows
curl -sL https://raw.githubusercontent.com/chrisribe/tagship/main/deploy.yml > .github/workflows/deploy.yml
```
Edit the URL in the file to match your domain (`tagship.yourdomain.com`), then:
```bash
git add .github/workflows/deploy.yml
git commit -m "Add tagship deploy workflow"
git push
```

**Step 2 — Add deploy token as GitHub secret:**
- Repo → Settings → Secrets and variables → Actions → New secret
- Name: `DEPLOY_TOKEN`
- Value: run `tagship token` on your server to get it

**Step 3 — Register repo on server (if not already done):**
```bash
tagship add yourusername/your-repo
```

**Step 4 — Deploy:**
```bash
git tag v1.0.0 && git push --tags
```

That's it. Every future `git tag vX.Y.Z && git push --tags` auto-deploys.

## CLI Reference

```bash
tagship add <user/repo>     # Register a repo for auto-deploy
tagship remove <user/repo>  # Unregister a repo
tagship list                # Show registered repos
tagship status              # Container health + recent deploys
tagship logs [n]            # Tail deploy logs
tagship token               # Show deploy token (for GitHub secrets)
tagship restart             # Rebuild & restart webhook
```

## Adding a New Repo Later

```bash
# On server:
tagship add yourusername/new-repo

# On dev machine:
cd new-repo
mkdir -p .github/workflows
curl -sL https://raw.githubusercontent.com/chrisribe/tagship/main/deploy.yml > .github/workflows/deploy.yml
# Edit URL, commit, push
# Add DEPLOY_TOKEN secret on GitHub
# Done — git tag v1.0.0 && git push --tags
```

## Known Gaps

- No rollback automation — manual: `git checkout <prev-tag> && docker compose up --build -d`
- No health check post-deploy
- No deploy notifications
- Single shared token across repos (fine for solo/small team)
