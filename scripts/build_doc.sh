#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Base directory configuration
DOCS_BASE_DIR="docs"
DIST_DIR="docs/dist"
LUA_FILTER="scripts/fix_pdf_links.lua"

# Ensure output directory exists
mkdir -p "$DIST_DIR"

# Function to build a documentation bundle
build_doc() {
  local doc_name="$1"
  local doc_dir="${DOCS_BASE_DIR}/${doc_name}"

  if [ ! -d "$doc_dir" ]; then
    echo "Error: Directory '$doc_dir' does not exist."
    exit 1
  fi

  # Output PDF named directly after the target directory without legacy prefixes
  local output_pdf="${DIST_DIR}/${doc_name}.pdf"
  local doc_files=()

  # Custom file order via files.txt if provided, otherwise auto-discovery
  if [ -f "${doc_dir}/files.txt" ]; then
    echo "Using custom file order from ${doc_dir}/files.txt..."
    while IFS= read -r line || [ -n "$line" ]; do
      [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
      doc_files+=("$line")
    done < "${doc_dir}/files.txt"
  else
    echo "Auto-discovering markdown files in ${doc_dir}..."

    # Ensure title page is placed first if present
    if [ -f "${doc_dir}/00-title.md" ]; then
      doc_files+=("${doc_dir}/00-title.md")
    fi

    # Append all remaining markdown files alphabetically, excluding title and index
    while IFS= read -r -d '' file; do
      doc_files+=("$file")
    done < <(find "$doc_dir" -type f -name "*.md" ! -name "00-title.md" ! -name "index.md" -print0 | sort -z)
  fi

  if [ ${#doc_files[@]} -eq 0 ]; then
    echo "Warning: No markdown files found in '$doc_dir'. Skipping."
    return 0
  fi

  echo "Compiling '${doc_name}' (${#doc_files[@]} files) -> ${output_pdf}..."

  # Pandoc options for XeLaTeX compilation
  local pandoc_options=(
    --pdf-engine=xelatex
    --lua-filter="$LUA_FILTER"
    -V mainfont="DejaVu Sans"
    -V sansfont="DejaVu Sans"
    -V monofont="DejaVu Sans Mono"
    -V geometry:margin=2cm
    -V colorlinks=true
    -V linkcolor=blue
    -V urlcolor=blue
    -V lang=ru-RU
    --toc-depth=3
  )

  pandoc "${doc_files[@]}" \
    -o "$output_pdf" \
    "${pandoc_options[@]}"

  echo "Successfully built: ${output_pdf}"
}

# Target document bundle specified as argument, or build all
TARGET="${1:-all}"

if [ "$TARGET" = "all" ]; then
  echo "Building all documentation in '${DOCS_BASE_DIR}'..."
  for dir in "${DOCS_BASE_DIR}"/*; do
    if [ -d "$dir" ] && [ "$(basename "$dir")" != "dist" ]; then
      build_doc "$(basename "$dir")"
    fi
  done
else
  build_doc "$TARGET"
fi