#!/usr/bin/env bash
# Collect project source code, tests, and configurations into a single context.txt file.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_FILE="${REPO_ROOT}/context.txt"

# Clean up previous dump if present
rm -f "${OUTPUT_FILE}"

echo "Collecting project context into ${OUTPUT_FILE}..."

# Traverse the repository, prune non-source directories, and append matching files
find "${REPO_ROOT}" \
    -type d \( \
        -name ".git" -o \
        -name "target" -o \
        -name "build" -o \
        -name ".dart_tool" -o \
        -name ".pub" -o \
        -name ".pub-cache" -o \
        -name ".idea" -o \
        -name ".vscode" -o \
        -name "storage" -o \
        -name "logs" -o \
        -name "dist" -o \
        -name "mutants.out" -o \
        -name "ephemeral" -o \
        -name "CMakeFiles" \
    \) -prune -o \
    -type f \( \
        -name "*.rs" -o \
        -name "*.dart" -o \
        -name "*.toml" -o \
        -name "*.yaml" -o \
        -name "*.yml" -o \
        -name "*.sh" -o \
        -name "*.lua" -o \
        -name "*.wgsl" -o \
        -name "*.md" -o \
        -name "*.json" -o \
        -name "justfile" -o \
        -name "VERSION" \
    \) \
    ! -name "context.txt" \
    ! -name "project_context.txt" \
    ! -name "changes.txt" \
    ! -name "*.g.dart" \
    -print | sort | while IFS= read -r file; do
        rel_path="${file#"${REPO_ROOT}/"}"
        echo "--- START OF FILE ${rel_path} ---" >> "${OUTPUT_FILE}"
        cat "${file}" >> "${OUTPUT_FILE}"
        echo "" >> "${OUTPUT_FILE}"
        echo "--- END OF FILE ${rel_path} ---" >> "${OUTPUT_FILE}"
        echo "" >> "${OUTPUT_FILE}"
    done

echo "Context file successfully created: ${OUTPUT_FILE}"