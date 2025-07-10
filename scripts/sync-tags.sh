#!/bin/bash
# sync-tags.sh
# Version: 0.0.14
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

# Fetch remote tags and branch
echo "Fetching remote tags and branches..."
git fetch origin --tags --force --prune --prune-tags

# Reset master branch to match remote
echo "Resetting master branch to origin/master..."
git checkout master
git reset --hard origin/master
git clean -f -d

# Delete local tags
echo "Deleting local tags..."
git tag -l | xargs git tag -d || true

# Create tags
echo "Creating tags..."
git tag -a v0.1.0 76c9d14 -m "Release v0.1.0"
git tag -a v0.2.0 338fd0d -m "Release v0.2.0"
git tag -a v0.3.0 532c5ec -m "Release v0.3.0"
git tag -a v0.4.0 7fc0d67 -m "Release v0.4.0"
git tag -a v0.5.0 c272659 -m "Release v0.5.0"
git tag -a v0.6.0 c3d5733 -m "Release v0.6.0"
git tag -a v0.7.0 c3b955c -m "Release v0.7.0"
git tag -a v0.8.0 7670625 -m "Release v0.8.0"
git tag -a v0.9.0 7d6dfc0 -m "Release v0.9.0"
git tag -a v0.10.0 ec3258e -m "Release v0.10.0"
git tag -a v0.10.1 eee2366 -m "Release v0.10.1"
git push origin v0.1.0 v0.2.0 v0.3.0 v0.4.0 v0.5.0 v0.6.0 v0.7.0 v0.8.0 v0.9.0 v0.10.0 v0.10.1

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

# Update markdownlint config
echo "Updating markdownlint config..."
cat >.markdownlint.json <<EOL
{
  "default": true,
  "MD025": { "level": 2 },
  "MD001": false,
  "MD003": { "style": "atx" },
  "MD004": { "style": "dash" },
  "MD007": { "indent": 2 },
  "MD013": { "line_length": 150 },
  "MD024": false,
  "MD031": true,
  "MD032": true,
  "MD046": { "style": "fenced" },
  "no-hard-tabs": false,
  "whitespace": false
}
EOL

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
pnpm format || {
  echo "ERROR: Formatting failed."
  exit 1
}

# Commit changelog, package.json, and markdownlint config if changed
if git diff --quiet CHANGELOG.md package.json .markdownlint.json; then
  echo "No changes to CHANGELOG.md, package.json, or .markdownlint.json, skipping commit..."
else
  git add CHANGELOG.md package.json .markdownlint.json
  git commit -m "chore: sync changelog, version, and markdownlint config" || true
  git push origin master
fi

# Verify working directory is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: Working directory not clean after sync:"
  git status
  exit 1
fi

# Validate release URLs
echo "Validating release URLs..."
grep -o 'https://github.com/DavitTec/usb_probe/\(compare\|releases/tag\)/[^)]*' CHANGELOG.md | while read -r url; do
  if curl --output /dev/null --silent --head --fail "$url"; then
    echo "URL valid: $url"
  else
    echo "ERROR: URL invalid: $url"
    exit 1
  fi
done

# Validate commit URLs
echo "Validating commit URLs..."
grep -o 'https://github.com/DavitTec/usb_probe/commit/[^)]*' CHANGELOG.md | while read -r url; do
  if curl --output /dev/null --silent --head --fail "$url"; then
    echo "URL valid: $url"
  else
    echo "ERROR: Commit URL invalid: $url"
    exit 1
  fi
done

echo "Tag, branch, and changelog sync complete. Check CHANGELOG.md and GitHub Releases."

# End of script
