#!/usr/bin/env bash
# Collect Git uncommitted modifications (status, staged/unstaged diffs, and untracked files) into changes.txt
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_FILE="${REPO_ROOT}/changes.txt"

# Remove existing changes report if present
rm -f "${OUTPUT_FILE}"

echo "Collecting uncommitted changes into ${OUTPUT_FILE}..."

{
  echo "=== GIT STATUS ==="
  git -C "${REPO_ROOT}" status --short
  echo ""

  echo "=== UNSTAGED DIFF ==="
  git -C "${REPO_ROOT}" diff
  echo ""

  echo "=== STAGED DIFF ==="
  git -C "${REPO_ROOT}" diff --cached
  echo ""

  echo "=== UNTRACKED NEW FILES CONTENT ==="
  git -C "${REPO_ROOT}" ls-files --others --exclude-standard | while IFS= read -r rel_path; do
    # Skip temporary files, diff dumps, and binary extensions
    case "${rel_path}" in
      changes.txt|context.txt|*.lock|*.log|*.png|*.jpg|*.ico|*.pdf|*.g.dart)
        continue
        ;;
    esac

    full_path="${REPO_ROOT}/${rel_path}"
    if [ -f "${full_path}" ]; then
      echo ""
      echo "--- START OF UNTRACKED FILE: ${rel_path} ---"
      cat "${full_path}"
      echo ""
      echo "--- END OF UNTRACKED FILE: ${rel_path} ---"
    fi
  done
  echo ""
} > "${OUTPUT_FILE}"

echo "Changes report successfully generated: ${OUTPUT_FILE} ($(wc -l < "${OUTPUT_FILE}") lines)."