#!/bin/bash
# sync-tags.sh
# Version: 0.0.6
# Purpose: Sync local tags, branch, and changelog with remote GitHub repository

# Exit on error
set -e

# Backup repository
REPO_DIR="/opt/davit/development/usb_probe"
BACKUP_DIR="/opt/davit/development/usb_probe_backup_$(date +%Y%m%d_%H%M%S)"
echo "Backing up $REPO_DIR to $BACKUP_DIR"
cp -r "$REPO_DIR" "$BACKUP_DIR"

# Switch to repository directory
cd "$REPO_DIR"

# Check for staged or unstaged changes
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: Working directory not clean. Please commit or stash changes:"
  git status
  exit 1
fi

# Delete all local tags
echo "Deleting local tags..."
git tag -l | xargs git tag -d || true

# Fetch remote tags and branch
echo "Fetching remote tags and branches..."
git fetch origin --tags --force --prune --prune-tags

# Reset master branch to match remote
echo "Resetting master branch to origin/master..."
git checkout master
git reset --hard origin/master
git clean -f -d

# Verify tags
echo "Local tags:"
git tag -l
echo "Remote tags:"
git ls-remote --tags origin

# Sync package.json version with latest tag
LATEST_TAG=$(git tag -l | sort -V | tail -n 1)
LATEST_VERSION=${LATEST_TAG#v}
echo "Syncing package.json version to $LATEST_VERSION..."
pnpm version "$LATEST_VERSION" --no-git-tag-version || {
  echo "ERROR: Failed to sync package.json version."
  exit 1
}

# Regenerate changelog
echo "Regenerating changelog..."
pnpm changelog:first || {
  echo "ERROR: Changelog generation failed."
  exit 1
}
pnpm changelog:fix || {
  echo "ERROR: Changelog fix failed."
  exit 1
}

# Commit changelog and package.json if changed
if git diff --quiet CHANGELOG.md package.json; then
  echo "No changes to CHANGELOG.md or package.json, skipping commit..."
else
  git add CHANGELOG.md package.json
  git commit -m "chore: sync changelog and version with tags" || true
  git push origin master
fi

# Verify working directory is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: Working directory not clean after sync:"
  git status
  exit 1
fi

# Validate changelog URLs
echo "Validating changelog URLs..."
grep -o 'https://github.com/DavitTec/USB_probe/compare/[^)]*' CHANGELOG.md | while read -r url; do
  if curl --output /dev/null --silent --head --fail "$url"; then
    echo "URL valid: $url"
  else
    echo "ERROR: URL invalid: $url"
    exit 1
  fi
done

echo "Tag, branch, and changelog sync complete. Check CHANGELOG.md and GitHub Releases."

# end of script
