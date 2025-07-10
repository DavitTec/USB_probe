# Issues_changelog.md

## Overview

This document summarizes the issues encountered with the `CHANGELOG.md` file in the `usb_probe` project, their root causes, solutions applied, and lessons learned to prevent recurrence across 70+ GitHub projects using similar versioning and changelog workflows. The primary issue was 404 errors in commit and comparison URLs due to a repository URL mismatch in `package.json`, followed by incorrect Markdown headers. Line length violations (`MD013`) were initially addressed with a wrapping script but ultimately resolved by disabling `MD013` to avoid breaking tables and URLs. The solutions ensure robust automation for changelog generation, tag management, and Markdown formatting without enforcing line length limits.

## Issues Encountered

1. **404 Errors in `CHANGELOG.md` URLs**:
   - **Description**: Commit URLs (e.g., `https://github.com/davittec/usb-probe/commit/bcae97a4e7624efedc4bec07dc5ec2cc4af6796e`) and comparison URLs (e.g., `https://github.com/davittec/usb-probe/compare/v0.8.0...v0.9.0`) returned 404 errors.
   - **Root Cause**: Incorrect `package.json` `name` (`usb-probe` instead of `usb_probe`) and `repository` URL (`git+https://github.com/davittec/usb-probe.git` instead of `git+https://github.com/DavitTec/usb_probe.git`) caused `conventional-changelog` to generate wrong URLs. Repeated tag deletions and repository recreation broke GitHub’s comparison cache. Stale commits (e.g., `bcae97a`) from the old repository were included.
   - **Impact**: Broken URLs disrupted release documentation and traceability.

2. **Incorrect Markdown Headers**:
   - **Description**: `conventional-changelog` generated `h1` (`#`) headers for version sections (e.g., `# [0.10.0]`), causing `markdownlint` errors (`MD025`: single top-level heading, `MD001`: heading increment) and requiring manual fixes to use `h2` (`##`).
   - **Root Cause**: Lack of header customization in `conventional-changelog` configuration and insufficient header correction in `changelog-fix.sh`.
   - **Impact**: Manual edits were needed, slowing down the release process.

3. **Markdown Line Length Violations**:
   - **Description**: Lines in `docs/Issues_changelog.md` and `CHANGELOG.md` exceeded the 150-character limit, triggering `MD013` errors during `pnpm format` in the `husky` pre-commit hook. Attempts to wrap lines with `wrap_md.sh` (using `fold` and `awk`) broke Markdown tables and URLs, and a Python-based version caused shell command injection errors (e.g., `sh: 1: CHANGELOG.md: not found`).
   - **Root Cause**: Long lines (e.g., lines 15, 16, 32 in `Issues_changelog.md`) exceeded the `MD013` limit in `.markdownlint.json` (`line_length: 150`). Wrapping scripts (`fold`, `awk`, Python) failed to preserve table rows (e.g., `| Name | Description |`) and URLs (e.g., `https://github.com/DavitTec/usb_probe/blob/master/scripts/wrap_md.sh`). Incorrect quoting in `awk` caused shell errors. A `Permission denied` error for `docs/Issues_changelog.md` indicated file permission issues.
   - **Impact**: `husky` pre-commit hook failed, and broken tables/URLs made documentation unusable. Shell errors disrupted automation.

4. **Script Errors**:
   - **Description**: `changelog-fix.sh` failed with `ERR_PNPM_NO_SCRIPT` due to a missing `prettier` script. `wrap_md.sh` broke tables and URLs, caused shell command injection errors, and hit a `Permission denied` error.
   - **Root Cause**: `package.json` lacked a `prettier` script, and `changelog-fix.sh` called `pnpm run prettier`. `wrap_md.sh` used flawed `awk` logic, and incorrect file permissions caused access issues.
   - **Impact**: Script failures disrupted automation.

5. **Tag and Release Mismatches**:
   - **Description**: Tags (`v0.1.0` to `v0.10.2`) were deleted and recreated multiple times, and some versions lacked tags or releases.
   - **Root Cause**: Frequent tag deletions and missing `git tag` commands in release workflows caused inconsistencies.
   - **Impact**: Missing tags broke comparison URLs and release workflows.

6. **Stale Commit References**:
   - **Description**: `conventional-changelog` included non-existent commits (e.g., `bcae97a`, `c272659`).
   - **Root Cause**: Possible caching in `node_modules` or `pnpm` store, or metadata from the old repository.
   - **Impact**: Invalid commit URLs required manual changelog fixes.

## Solutions Applied

1. **Fixed `package.json`**:
   - Updated `name` to `usb_probe` and `repository` to `git+https://github.com/DavitTec/usb_probe.git`.
   - Added `prettier` script (`"prettier": "prettier --write ."`) and `conventionalChangelog` configuration to enforce correct URLs and `h2` headers.
   - Removed `wrap:md` script after disabling `MD013`.

2. **Corrected `CHANGELOG.md`**:
   - Used a single `h1` header (`# CHANGELOG`) and `h2` headers for versions (e.g., `## [0.10.2]`).
   - Replaced invalid commit URLs with valid ones from `git log` (e.g., `eee2366`, `ec3258e`).
   - Used comparison URLs (e.g., `https://github.com/DavitTec/usb_probe/compare/v0.10.0...v0.10.1`) with release pages as a fallback.

3. **Disabled Line Length Checks**:
   - Set `"MD013": false` in `.markdownlint.json` to disable line length validation, avoiding issues with tables and URLs.
   - Created `.markdownlintignore` to exclude `./.davit/`, `archives/`, `logs/`, and optionally `docs/Issues_changelog.md`.
   - Removed `wrap_md.sh` from `husky` pre-commit and `package.json` to prevent unnecessary wrapping.
   - Cleared `pnpm` cache to ensure updated `markdownlint` configuration:

     ```bash
     pnpm store prune
     rm -rf node_modules
     pnpm install
     ```

4. **Fixed File Permissions**:
   - Set correct permissions for `docs/Issues_changelog.md`:

     ```bash
     chmod 644 docs/Issues_changelog.md
     chown david:david docs/Issues_changelog.md
     ```

5. **Updated Scripts**:
   - `changelog-fix.sh`: Added `sed` commands for `h2` headers and URL validation.
   - `sync-tags.sh`: Automated tag recreation for `v0.1.0` to `v0.10.2` and included URL validation.
   - `release.sh`: Enforced header fixes and URL validation during releases.
   - Removed `wrap_md.sh` to avoid wrapping issues with tables and URLs.

6. **Recreated Tags and Releases**:
   - Created tags (`v0.1.0` to `v0.10.2`) aligned with commits (e.g., `v0.10.1` → `eee2366`).
   - Used `gh release create` for GitHub releases.

7. **Cleared Caches**:
   - Ran `pnpm store prune` and `rm -rf node_modules; pnpm install` to clear stale data.

## Lessons Learned

1. **Check `package.json` First**:
   - Verify `name` and `repository.url` match the GitHub repository (`DavitTec/<repo>`).
   - Command: `grep '"name"' package.json; grep '"repository"' package.json`.

2. **Configure `conventional-changelog`**:
   - Add `conventionalChangelog` in `package.json` with `header: "# CHANGELOG\n\n"` and `writerOpts` for `h2` headers.
   - Example:

     ```json
     "writerOpts": {
       "mainTemplate": "{{> header}}{{#each commitGroups}}\n## [{{commitGroupTitle}}]({{commitGroupUrl}}) ({{dateFormat date 'YYYY-MM-DD'}})\n\n{{#each commits}}{{> commit}}\n{{/each}}{{/each}}",
       "headerPartial": "",
       "commitPartial": "- {{commit.message}} ([{{commit.hash}}]({{commit.commitUrl}}))\n"
     }
     ```

3. **Automate Markdown Formatting**:
   - Use `sed` in `changelog-fix.sh` for `h2` headers:

     ```bash
     sed -i -E 's/^# \[(.*)\]\((.*)\)/## [\1](\2)/g' CHANGELOG.md
     sed -i '1s/^/# CHANGELOG\n\n/' CHANGELOG.md
     sed -i '/^# CHANGELOG/{2,$d}' CHANGELOG.md
     ```

   - Avoid line wrapping scripts (`wrap_md.sh`) if they break tables or URLs; disable `MD013` instead.

4. **Handle Line Length**:
   - Disable `MD013` in `.markdownlint.json` (`"MD013": false`) to allow long lines in tables and URLs.
   - Use `.markdownlintignore` to exclude non-critical directories (e.g., `archives/`, `logs/`).
   - Check long lines if needed: `awk 'length($0) > 150 {print NR, $0}' docs/Issues_changelog.md`.

5. **Validate URLs**:
   - Add `curl --head` checks in scripts to validate commit and comparison URLs.
   - Fallback to release pages if comparison URLs 404.

6. **Manage Tags**:
   - Avoid frequent tag deletions to preserve GitHub’s comparison cache.
   - Use `sync-tags.sh` to reset tags:

     ```bash
     git push origin --delete $(git tag -l)
     git tag -d $(git tag -l)
     git tag -a vX.Y.Z <commit> -m "Release vX.Y.Z"
     git push origin --tags
     ```

7. **Clear Caches**:
   - Run `pnpm store prune` and `rm -rf node_modules; pnpm install` after configuration changes.

8. **Standardize Across Projects**:
   - Apply consistent `package.json` scripts, `conventionalChangelog`, and helper scripts (`changelog-fix.sh`, `sync-tags.sh`, `release.sh`) to all projects.
   - Create a shared `scripts/utils` directory for utilities like logging, archiving, staging, and installs.

## Applying to Other Projects

- **Update `package.json`**:
  - Ensure `name` matches the repository name (e.g., `usb_probe`).
  - Set `repository.url` to `git+https://github.com/DavitTec/<repo>.git`.
  - Include `conventionalChangelog` and scripts (`prettier`, `format`, etc.).
- **Copy Scripts**:
  - Use `changelog-fix.sh`, `sync-tags.sh`, `release.sh` in all projects.
  - Update repository URLs and paths in scripts.
- **Shared Utilities**:
  - Create `scripts/utils` for logging, archiving, staging, and install/uninstall scripts.
  - Example: `"archive": "./scripts/utils/archive.sh"` in `package.json`.
- **Automate Tag Resets**:
  - Adapt `sync-tags.sh` for each project, mapping commits to versions using `git log`.
- **Disable `MD013`**:
  - Set `"MD013": false` in `.markdownlint.json` for all projects to avoid line length issues.
  - Use `.markdownlintignore` to exclude non-critical files.

## Git Best Practices

- **Error Detection**:
  - Run `git log --oneline --graph --decorate` to verify commits.
  - Check tags: `git ls-remote --tags origin`.
  - Validate URLs: `curl --head <url>`.
- **Conventional Commits**:
  - Use `pnpm cz` for consistent commit messages (e.g., `fix:`, `feat:`).
- **Backup**:
  - Back up repositories: `cp -r <repo> <backup_dir>`.
- **Adapt Old-School Methods**:
  - **Staging**: Use Git branches (e.g., `git checkout -b staging`).
  - **Diffs**: Use `git diff`.
  - **Packaging**: Use `git archive` for version snapshots.
  - **Archiving**: Script backups with `tar` or `zip`.

## TODO and Modifications to Consider

1. **Review Line Length Strategy**:
   - Monitor readability in rendered Markdown without `MD013` enforcement.
   - Reintroduce selective line wrapping (e.g., prose only) if needed, using a more robust tool like Prettier or Remark CLI:

     ```bash
     npx prettier --write --prose-wrap always --print-width 150 CHANGELOG.md docs/*.md
     ```

2. **Create Shared Script Library**:
   - Develop `scripts/utils` directory with scripts for:
     - Logging: `logging.sh` (already used).
     - Archiving: `archive.sh` (e.g., `git archive --format=tar.gz -o archive-vX.Y.Z.tar.gz vX.Y.Z`).
     - Staging: `staging.sh` (e.g., create and manage `staging` branch).
     - Install/Uninstall: `install.sh`, `uninstall.sh` for project setup/teardown.
   - Add to `package.json`: `"archive": "./scripts/utils/archive.sh"`, etc.

3. **Automate Across Projects**:
   - Create a template repository with `package.json`, scripts, `.markdownlint.json`, and `.markdownlintignore`.
   - Use a script to copy configurations to other projects:

     ```bash
     cp -r scripts package.json .markdownlint.json .markdownlintignore ../other_project/
     ```

4. **CI Pipeline**:
   - Set up GitHub Actions to run `pnpm format` and URL validation:

     ```yaml
     name: Validate Changelog
     on: [push]
     jobs:
       validate:
         runs-on: ubuntu-latest
         steps:
           - uses: actions/checkout@v3
           - run: pnpm install
           - run: pnpm format
           - run: ./scripts/sync-tags.sh
     ```

5. **Improve Error Detection**:
   - Add `check_repo.sh` to validate `package.json` consistency:

     ```bash
     # check_repo.sh
     REPO_NAME=$(basename $(git config --get remote.origin.url) .git)
     PKG_NAME=$(jq -r '.name' package.json)
     if [ "$REPO_NAME" != "$PKG_NAME" ]; then
       echo "ERROR: package.json name ($PKG_NAME) does not match repo ($REPO_NAME)"
       exit 1
     fi
     ```

6. **Document Old-School Workflows**:
   - Create `docs/Workflows.md` to describe staging, diffs, packaging, and archiving in a Git context.
   - Example:

     ```markdown
     ## Staging

     - Create a staging branch: `git checkout -b staging`
     - Merge to master: `git checkout master; git merge staging`

     ## Archiving

     - Create a version archive: `git archive --format=tar.gz -o archive-vX.Y.Z.tar.gz vX.Y.Z`
     ```

7. **Test Across Projects**:
   - Apply `"MD013": false` and `.markdownlintignore` to other projects.
   - Ensure table and URL integrity in rendered Markdown.

## Script Table

| Name                                                                                           | Description                                                                       | Version | Last Update |
| ---------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- | ------- | ----------- |
| [changelog-fix.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/changelog-fix.sh) | Formats `CHANGELOG.md`, ensures `h2` headers, and validates URLs.                 | 0.2.11  | 20250710    |
| [sync-tags.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/sync-tags.sh)         | Syncs tags, recreates tags (`v0.1.0` to `v0.10.2`), and validates changelog URLs. | 0.0.16  | 20250710    |
| [release.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/release.sh)             | Manages version bumps, changelog generation, and release creation.                | 0.2.16  | 20250710    |
| [logging.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/logging.sh)             | Provides logging utilities for other scripts (assumed to exist).                  | 0.2.1   | 20250708    |
| [archive.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/utils/archive.sh)       | Archives project versions using `git archive` (placeholder, create if needed).    | 0.1.0   | 20250710    |
| [staging.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/utils/staging.sh)       | Manages staging branches and merges (placeholder, create if needed).              | 0.1.0   | 20250710    |
| [install.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/utils/install.sh)       | Sets up project dependencies and environment (placeholder, create if needed).     | 0.1.0   | 20250710    |
| [uninstall.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/utils/uninstall.sh)   | Removes project setup and cleans environment (placeholder, create if needed).     | 0.1.0   | 20250710    |

## Troubleshooting Guide

- **404 URLs**:
  - Check `package.json` `name` and `repository.url`.
  - Verify commits: `git show <hash>`.
  - Use release pages: `https://github.com/DavitTec/<repo>/releases/tag/vX.Y.Z`.
- **Incorrect Headers**:
  - Check `conventionalChangelog` in `package.json`.
  - Run `pnpm changelog:fix` to fix headers.
- **Line Length Errors (`MD013`)**:
  - Ensure `"MD013": false` in `.markdownlint.json`.
  - Verify `.markdownlintignore` excludes non-critical files (e.g., `archives/`, `logs/`).
  - Clear cache: `pnpm store prune; rm -rf node_modules; pnpm install`.
  - Check: `pnpm format`.
- **Script Failures**:
  - Verify `package.json` scripts (`prettier`, `format`).
  - Check `.env` and script paths.
  - Ensure file permissions: `ls -l docs/Issues_changelog.md; chmod 644 docs/Issues_changelog.md`.
- **Tag Issues**:
  - Compare `git tag -l` and `git ls-remote --tags origin`.
  - Reset tags with `sync-tags.sh`.

## Future Improvements

1. **Monitor Line Length**:
   - Periodically check readability in rendered Markdown without `MD013`.
   - Consider selective wrapping with Prettier if needed:

     ```bash
     npx prettier --write --prose-wrap always --print-width 150 CHANGELOG.md docs/*.md
     ```

2. **Create Shared Script Library**:
   - Develop `scripts/utils` with `archive.sh`, `staging.sh`, `install.sh`, `uninstall.sh`.
   - Example `archive.sh`:

     ```bash
     #!/bin/bash
     TAG=$(git tag -l | sort -V | tail -n 1)
     git archive --format=tar.gz -o "archive-$TAG.tar.gz" "$TAG"
     ```

3. **Template Repository**:
   - Create a GitHub template with `package.json`, scripts, `.markdownlint.json`, and `.markdownlintignore`.

4. **CI Pipeline**:
   - Use GitHub Actions for validation:

     ```yaml
     name: Validate Changelog
     on: [push]
     jobs:
       validate:
         runs-on: ubuntu-latest
         steps:
           - uses: actions/checkout@v3
           - run: pnpm install
           - run: pnpm format
           - run: ./scripts/sync-tags.sh
     ```

5. **Error Detection Script**:
   - Add `check_repo.sh` to validate `package.json` consistency:

     ```bash
     # check_repo.sh
     REPO_NAME=$(basename $(git config --get remote.origin.url) .git)
     PKG_NAME=$(jq -r '.name' package.json)
     if [ "$REPO_NAME" != "$PKG_NAME" ]; then
       echo "ERROR: package.json name ($PKG_NAME) does not match repo ($REPO_NAME)"
       exit 1
     fi
     ```

6. **Document Old-School Workflows**:
   - Create `docs/Workflows.md` for staging, diffs, packaging, and archiving.

7. **Test Across Projects**:
   - Apply `"MD013": false` and `.markdownlintignore` to other projects.
   - Ensure table and URL integrity in rendered Markdown.
