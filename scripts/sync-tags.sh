#!/bin/bash
# sync-tags.sh
# Version: 0.0.2
# Exit on error
set -e

# Backup repository
REPO_DIR="/opt/davit/development/usb_probe"
BACKUP_DIR="/opt/davit/development/usb_probe_backup_$(date +%Y%m%d_%H%M%S)"
echo "Backing up $REPO_DIR to $BACKUP_DIR"
cp -r "$REPO_DIR" "$BACKUP_DIR"

# Switch to repository directory
cd "$REPO_DIR"

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

# Optional: Regenerate changelog (uncomment if using git-chglog)
echo "Regenerating changelog..."
# git-chglog --output CHANGELOG.md
pnpm conventional-changelog -p angular -i CHANGELOG.md -s
pnpm changelog:fix

git add CHANGELOG.md
git commit -m "Update changelog to sync with tags" || true
git push origin master

echo "Tag sync complete. Check CHANGELOG.md and GitHub Releases."

# end of script
