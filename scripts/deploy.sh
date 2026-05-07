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

git fetch --tags
git checkout "tags/$TAG"

docker compose up --build -d

echo "Done: $REPO @ $TAG"
