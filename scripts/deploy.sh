#!/bin/bash
set -e

REPO=$1   # e.g. chrisribe/my-service
TAG=$2    # e.g. v1.0.3

# Map repo name to deploy path
# Add an entry per subdomain service
declare -A REPO_PATHS=(
  ["chrisribe/tagship"]="/opt/stacks/tagship"
  ["chrisribe/pixagreat-web"]="/opt/stacks/pixagreat-web"
  ["chrisribe/mood-tube"]="/opt/stacks/mood-tube"
)

DEPLOY_DIR="${REPO_PATHS[$REPO]}"

if [ -z "$DEPLOY_DIR" ]; then
  echo "Unknown repo: $REPO"
  exit 1
fi

echo "Deploying $REPO @ $TAG to $DEPLOY_DIR"

cd "$DEPLOY_DIR"

git fetch --tags --force
git reset --hard
git checkout "tags/$TAG"

# Rebuild if Dockerfile exists, otherwise restart to pick up volume changes
if [ -f Dockerfile ] || grep -q "build:" docker-compose.yml 2>/dev/null; then
  docker compose up --build -d
else
  docker compose restart
fi

echo "Done: $REPO @ $TAG"
