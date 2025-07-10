# Issues_changelog.md

## Overview

This document summarizes the issues encountered with the `CHANGELOG.md` file in the `usb_probe` project, their root causes, solutions applied, and
lessons learned to prevent recurrence across 70+ GitHub projects using similar versioning and changelog workflows. The primary issue was 404 errors
in commit and comparison URLs due to a repository URL mismatch in `package.json`, followed by incorrect Markdown headers and line length violations
(`MD013`) requiring manual fixes. The solutions ensure robust automation for changelog generation, tag management, and Markdown formatting.

## Issues Encountered

1. **404 Errors in `CHANGELOG.md` URLs**:
   - **Description**: Commit URLs (e.g., `https://github.com/davittec/usb-probe/commit/bcae97a4e7624efedc4bec07dc5ec2cc4af6796e`) and comparison URLs
     (e.g., `https://github.com/davittec/usb-probe/compare/v0.8.0...v0.9.0`) returned 404 errors.
   - **Root Cause**: Incorrect `package.json` `name` (`usb-probe` instead of `usb_probe`) and `repository` URL
     (`git+https://github.com/davittec/usb-probe.git` instead of `git+https://github.com/DavitTec/usb_probe.git`) caused `conventional-changelog` to
     generate wrong URLs. Repeated tag deletions and repository recreation broke GitHub’s comparison cache. Stale commits (e.g., `bcae97a`) from
     the old
     repository were included.
   - **Impact**: Broken URLs disrupted release documentation and traceability.

2. **Incorrect Markdown Headers**:
   - **Description**: `conventional-changelog` generated `h1` (`#`) headers for version sections (e.g., `# [0.10.0]`), causing `markdownlint` errors
     (`MD025`: single top-level heading, `MD001`: heading increment) and requiring manual fixes to use `h2` (`##`).
   - **Root Cause**: Lack of header customization in `conventional-changelog` configuration and insufficient header correction in `changelog-fix.sh`.
   - **Impact**: Manual edits were needed, slowing down the release process.

3. **Markdown Line Length Violations**:
   - **Description**: Lines in `docs/Issues_changelog.md` exceeded the 150-character limit, triggering `MD013` errors during `pnpm format` in the
     `husky` pre-commit hook.
   - **Root Cause**: Long lines in Markdown files (e.g., lines 5, 10, 11, 15) exceeded the `MD013` limit set in `.markdownlint.json` (`line_length: 
   150`).
   - **Impact**: `husky` pre-commit hook failed, preventing commits until lines were wrapped manually or the limit was adjusted.

4. **Script Errors**:
   - **Description**: `changelog-fix.sh` failed with `ERR_PNPM_NO_SCRIPT` due to a missing `prettier` script in `package.json`.
   - **Root Cause**: `package.json` lacked a `prettier` script, and `changelog-fix.sh` called `pnpm run prettier` instead of `pnpm format`.
   - **Impact**: Script failures disrupted automated changelog generation.

5. **Tag and Release Mismatches**:
   - **Description**: Tags (`v0.1.0` to `v0.10.2`) were deleted and recreated multiple times, and some versions lacked tags or releases.
   - **Root Cause**: Frequent tag deletions and missing `git tag` commands in release workflows caused inconsistencies.
   - **Impact**: Missing tags broke comparison URLs and release workflows.

6. **Stale Commit References**:
   - **Description**: `conventional-changelog` included non-existent commits (e.g., `bcae97a`, `c272659`) in `CHANGELOG.md`.
   - **Root Cause**: Possible caching in `node_modules` or `pnpm` store, or metadata from the old repository persisting locally.
   - **Impact**: Invalid commit URLs required manual changelog fixes.

## Solutions Applied

1. **Fixed `package.json`**:
   - Updated `name` to `usb_probe` and `repository` to `git+https://github.com/DavitTec/usb_probe.git`.
   - Added `prettier` script (`"prettier": "prettier --write ."`) and `conventionalChangelog` configuration to enforce correct URLs and `h2` headers.
   - Example:

     ```json
     "conventionalChangelog": {
       "preset": "angular",
       "releaseCount": 0,
       "tagPrefix": "v",
       "header": "# CHANGELOG\n\n",
       "commitUrlFormat": "https://github.com/DavitTec/usb_probe/commit/{{hash}}",
       "compareUrlFormat": "https://github.com/DavitTec/usb_probe/compare/{{previousTag}}...{{currentTag}}"
     }
     ```

2. **Corrected `CHANGELOG.md`**:
   - Used a single `h1` header (`# CHANGELOG`) and `h2` headers for versions (e.g., `## [0.10.2]`).
   - Replaced invalid commit URLs with valid ones from `git log` (e.g., `eee2366`, `ec3258e`).
   - Used comparison URLs (e.g., `https://github.com/DavitTec/usb_probe/compare/v0.10.0...v0.10.1`) with release pages as a fallback for older tags.

3. **Fixed Line Length Violations**:
   - Created `wrap_md.sh` to wrap lines in `docs/*.md` to `$MAX_LINE_LENGTH` (set to 150 in `.env`) using `fold -s -w`.
   - Updated `husky` pre-commit hook to run `pnpm wrap:md` before `pnpm format` and `pnpm lint:sh`.
   - Added `"wrap:md": "exec scripts/wrap_md.sh"` to `package.json` scripts.
   - Added `MAX_LINE_LENGTH=150` to `.env` for flexibility.

4. **Updated Scripts**:
   - `changelog-fix.sh`: Added `sed` commands to convert `# [version]` to `## [version]`, ensure a single `# CHANGELOG`, and validate URLs.
   - `sync-tags.sh`: Automated tag recreation for `v0.1.0` to `v0.10.2` and included URL validation.
   - `release.sh`: Enforced header fixes, line wrapping, and URL validation during releases.
   - `wrap_md.sh`: Added to wrap lines in `docs/*.md` to `$MAX_LINE_LENGTH`.

5. **Recreated Tags and Releases**:
   - Created tags (`v0.1.0` to `v0.10.2`) aligned with commits from `git log` (e.g., `v0.10.1` → `eee2366`).
   - Used `gh release create` to create GitHub releases for each tag.

6. **Cleared Caches**:
   - Ran `pnpm store prune` and `rm -rf node_modules; pnpm install` to clear stale data.

## Lessons Learned

1.  **Check `package.json` First**:
    - Verify `name` and `repository.url` match the GitHub repository (`DavitTec/<repo>`).
    - Command: `grep '"name"' package.json; grep '"repository"' package.json`.

2.  **Configure `conventional-changelog`**:
    - Add `conventionalChangelog` in `package.json` with `header: "# CHANGELOG\n\n"` and `writerOpts` for `h2` headers.
    - Example:

    ```json
           "writerOpts": {
             "mainTemplate": "{{> header}}{{#each commitGroups}}\n## [{{commitGroupTitle}}]({{commitGroupUrl}}) ({{dateFormat date
    
      'YYYY-MM-DD'}})\n\n{{#each commits}}{{> commit}}\n{{/each}}{{/each}}",
      "headerPartial": "",
      "commitPartial": "- {{commit.message}} ([{{commit.hash}}]({{commit.commitUrl}}))\n"
      }
    
    ```

3.  **Automate Markdown Formatting**:
    - Use `sed` in `changelog-fix.sh` to enforce `h2` headers:

      ```bash
      sed -i -E 's/^# \[(.*)\]\((.*)\)/## [\1](\2)/g' CHANGELOG.md
      sed -i '1s/^/# CHANGELOG\n\n/' CHANGELOG.md
      sed -i '/^# CHANGELOG/{2,$d}' CHANGELOG.md
      ```

    - Use `wrap_md.sh` to wrap lines to `$MAX_LINE_LENGTH`:

      ```bash
      fold -s -w "$MAX_LINE_LENGTH" "$file" > "${file}.tmp"
      ```

4.  **Handle Line Length**:
    - Set `MAX_LINE_LENGTH` in `.env` (e.g., `150`) and use `wrap_md.sh` in pre-commit hooks.
    - Alternatively, increase `MD013` in `.markdownlint.json` (e.g., `line_length: 300`) if wrapping is impractical.

5.  **Validate URLs**:
    - Add `curl --head` checks in scripts to validate commit and comparison URLs.
    - Fallback to release pages (`https://github.com/DavitTec/<repo>/releases/tag/vX.Y.Z`) if comparison URLs 404.

6.  **Manage Tags**:
    - Avoid frequent tag deletions to preserve GitHub’s comparison cache.
    - Use `sync-tags.sh` to reset tags:

      ```bash
      git push origin --delete $(git tag -l)
      git tag -d $(git tag -l)
      git tag -a vX.Y.Z <commit> -m "Release vX.Y.Z"
      git push origin --tags
      ```

7.  **Clear Caches**:
    - Run `pnpm store prune` and `rm -rf node_modules; pnpm install` after repository changes.

8.  **Standardize Across Projects**:
    - Apply consistent `package.json` scripts, `conventionalChangelog` settings, and helper scripts (`wrap_md.sh`, `changelog-fix.sh`, `sync-tags.sh`,
      `release.sh`) to all projects.
    - Create a shared `scripts/utils` directory for utilities like logging, archiving, staging, and installs.

## Applying to Other Projects

- **Update `package.json`**:
  - Ensure `name` matches the repository name (e.g., `usb_probe`).
  - Set `repository.url` to `git+https://github.com/DavitTec/<repo>.git`.
  - Include `conventionalChangelog` and scripts (`wrap:md`, `prettier`, `format`, etc.).
- **Copy Scripts**:
  - Use `wrap_md.sh`, `changelog-fix.sh`, `sync-tags.sh`, `release.sh` in all projects.
  - Update repository URLs and paths in scripts.
- **Shared Utilities**:
  - Create `scripts/utils` for logging, archiving, staging, and install/uninstall scripts.
  - Example: `"archive": "./scripts/utils/archive.sh"` in `package.json`.
- **Automate Tag Resets**:
  - Adapt `sync-tags.sh` for each project, mapping commits to versions using `git log`.

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

1. **Enhance `wrap_md.sh`**:
   - Add `CHANGELOG.md` to the files processed by `wrap_md.sh`.
   - Example:

     ```bash
     fold -s -w "$MAX_LINE_LENGTH" CHANGELOG.md > CHANGELOG.md.tmp
     mv CHANGELOG.md.tmp CHANGELOG.md
     ```

   - Allow configurable file patterns in `.env` (e.g., `MD_FILES="CHANGELOG.md docs/*.md"`).

2. **Create Shared Script Library**:
   - Develop `scripts/utils` directory with scripts for:
     - Logging: `logging.sh` (already used).
     - Archiving: `archive.sh` (e.g., `git archive --format=tar.gz -o archive-vX.Y.Z.tar.gz vX.Y.Z`).
     - Staging: `staging.sh` (e.g., create and manage `staging` branch).
     - Install/Uninstall: `install.sh`, `uninstall.sh` for project setup/teardown.
   - Add to `package.json`: `"archive": "./scripts/utils/archive.sh"`, etc.

3. **Automate Across Projects**:
   - Create a template repository with `package.json`, scripts, and `.markdownlint.json`.
   - Use a script to copy configurations to other projects:

     ```bash
     cp -r scripts package.json .markdownlint.json ../other_project/
     ```

4. **CI Pipeline**:
   - Set up GitHub Actions to run `pnpm format`, `pnpm wrap:md`, and URL validation on push.
   - Example workflow:

     ```yaml
     name: Validate Changelog
     on: [push]
     jobs:
       validate:
         runs-on: ubuntu-latest
         steps:
           - uses: actions/checkout@v3
           - run: pnpm install
           - run: pnpm wrap:md
           - run: pnpm format
           - run: ./scripts/sync-tags.sh
     ```

5. **Improve Error Detection**:
   - Add a script to check `package.json` consistency:

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

## Script Table

| Name | Description | Version | Last Update |
| ----------------------------------------------------------------------------------------------
|------------------------------------------------------------------------------------------- | ------- | ----------- |
| [wrap_md.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/wrap_md.sh) | Wraps lines in Markdown files (`docs/*.md`) to
`$MAX_LINE_LENGTH` from `.env` using `fold`. | 0.0.1 | 20250710 |
| [changelog-fix.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/changelog-fix.sh) | Formats `CHANGELOG.md`, ensures `h2` headers,wraps
lines, and validates URLs. | 0.2.11 | 20250710 |
| [sync-tags.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/sync-tags.sh) | Syncs tags, recreates tags (`v0.1.0` to `v0.10.2`), and
validates changelog URLs. |0.0.16|20250710|
| [release.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/release.sh) | Manages version bumps, changelog generation, and release
creation. | 0.2.16 | 20250710 |
| [logging.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/logging.sh) | Provides logging utilities for other scripts (assumed to
exist). | 0.2.1 | 20250708 |
| [archive.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/utils/archive.sh) | Archives project versions using `git 
archive`(placeholder, create if needed). | 0.1.0 | 20250710 |
| [staging.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/utils/staging.sh) | Manages staging branches and merges (placeholder,create
if needed). | 0.1.0 | 20250710 |
| [install.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/utils/install.sh) | Sets up project dependencies and
environment,(placeholder, create if needed). | 0.1.0 | 20250710 |
| [uninstall.sh](https://github.com/DavitTec/usb_probe/blob/master/scripts/utils/uninstall.sh) | Removes project setup and cleans environment
(placeholder, create if needed). | 0.1.0 | 20250710 |

## Troubleshooting Guide

- **404 URLs**:
  - Check `package.json` `name` and `repository.url`.
  - Verify commits: `git show <hash>`.
  - Use release pages: `https://github.com/DavitTec/<repo>/releases/tag/vX.Y.Z`.
- **Incorrect Headers**:
  - Check `conventionalChangelog` in `package.json`.
  - Run `pnpm changelog:fix` to fix headers.
- **Line Length Errors (`MD013`)**:
  - Run `pnpm wrap:md` to wrap lines to `$MAX_LINE_LENGTH`.
  - Increase `MD013` in `.markdownlint.json` if needed: `"MD013": { "line_length": 300 }`.
  - Check: `awk 'length($0) > 150 {print NR, $0}' docs/Issues_changelog.md`.
- **Script Failures**:
  - Verify `package.json` scripts (`prettier`, `format`, `wrap:md`).
  - Check `.env` for `MAX_LINE_LENGTH` and script paths.
- **Tag Issues**:
  - Compare `git tag -l` and `git ls-remote --tags origin`.
  - Reset tags with `sync-tags.sh`.

## Future Improvements

1. **Integrate `wrap_md.sh` with `CHANGELOG.md`**:
   - Add `CHANGELOG.md` to `wrap_md.sh`:

     ```bash
     fold -s -w "$MAX_LINE_LENGTH" CHANGELOG.md > CHANGELOG.md.tmp
     mv CHANGELOG.md.tmp CHANGELOG.md
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
   - Create a GitHub template with `package.json`, scripts, and `.markdownlint.json`.
   - Clone for new projects: `gh repo create --template DavitTec/template`.
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
           - run: pnpm wrap:md
           - run: pnpm format
           - run: ./scripts/sync-tags.sh
     ```

5. **Error Detection Script**:
   - Create `check_repo.sh` to validate `package.json`:

     ```bash
     REPO_NAME=$(basename $(git config --get remote.origin.url) .git)
     PKG_NAME=$(jq -r '.name' package.json)
     if [ "$REPO_NAME" != "$PKG_NAME" ]; then
       echo "ERROR: package.json name ($PKG_NAME) does not match repo ($REPO_NAME)"
       exit 1
     fi
     ```
