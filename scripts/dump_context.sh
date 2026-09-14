#!/usr/bin/env bash
# Collect project structure manifest, source code, prompts, and configurations into a single context.txt file
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_FILE="${REPO_ROOT}/context.txt"

# Clean up previous dump if present
rm -f "${OUTPUT_FILE}"

echo "Collecting project context into ${OUTPUT_FILE}..."

{
  echo "--- START OF FILE host_environment_info.txt ---"
  echo "Host System Environment:"
  uname -srm
  if command -v flutter >/dev/null 2>&1; then
    flutter --version 2>&1 | head -n 2
  elif command -v dart >/dev/null 2>&1; then
    dart --version 2>&1
  fi
  echo "--- END OF FILE host_environment_info.txt ---"
  echo ""

  echo "--- START OF FILE project_structure_manifest.txt ---"
  echo "PROJECT STRUCTURE & CONTEXT PROFILE MANIFEST:"
  echo "  - [FULL      ] lib/src/config       : Конфигурация порогов прилипания и ограничений окон"
  echo "  - [FULL      ] lib/src/engine       : Чистое вычислительное ядро (геометрия, прилипание, тайлинг, швы)"
  echo "  - [FULL      ] lib/src/state        : Модели состояния, контракты геометрии и контроллеры Riverpod"
  echo "  - [FULL      ] lib/src/registry     : Реестр определений панелей и фабрик содержимого"
  echo "  - [FULL      ] lib/src/theme        : Контракт темы оформления рабочего пространства"
  echo "  - [FULL      ] lib/src/l10n         : Контракты локализации и строковые ресурсы"
  echo "  - [FULL      ] lib/src/presentation : Визуальные виджеты (холст, окна, панель задач)"
  echo "  - [FULL      ] test                 : Модульные и интеграционные тесты библиотеки"
  echo "  - [FULL      ] example              : Демонстрационное приложение использования библиотеки"
  echo "  - [FULL      ] scripts              : Shell-скрипты автоматизации сбора контекста и диффов"
  echo "  - [FULL      ] prompts              : Системные регламенты и промты разработки"
  echo "  - [FULL      ] root                 : Корневые файлы конфигурации (pubspec, analysis_options, justfile)"
  echo ""
  echo "DIRECTORY HIERARCHY:"
  find "${REPO_ROOT}" \
    -maxdepth 4 \
    -type d \( \
      -name ".git" -o \
      -name ".dart_tool" -o \
      -name ".pub" -o \
      -name ".pub-cache" -o \
      -name "build" -o \
      -name "coverage" -o \
      -name ".idea" -o \
      -name ".vscode" \
    \) -prune -o -type d -print | sort | while IFS= read -r dir; do
      rel_dir="${dir#"${REPO_ROOT}"}"
      [ -z "${rel_dir}" ] && continue
      echo "  * ${rel_dir#/}"
    done
  echo "--- END OF FILE project_structure_manifest.txt ---"
  echo ""

  # Traverse the repository, prune non-source directories, and append matching files
  find "${REPO_ROOT}" \
    -type d \( \
      -name ".git" -o \
      -name "build" -o \
      -name "coverage" -o \
      -name ".dart_tool" -o \
      -name ".pub" -o \
      -name ".pub-cache" -o \
      -name ".idea" -o \
      -name ".vscode" \
    \) -prune -o \
    -type f \( \
      -name "*.dart" -o \
      -name "*.yaml" -o \
      -name "*.yml" -o \
      -name "*.sh" -o \
      -name "*.md" -o \
      -name "*.json" -o \
      -name "justfile" \
    \) \
    ! -name "context.txt" \
    ! -name "changes.txt" \
    ! -name "*.g.dart" \
    -print | sort | while IFS= read -r file; do
      rel_path="${file#"${REPO_ROOT}/"}"
      echo "--- START OF FILE ${rel_path} ---"
      cat "${file}"
      echo ""
      echo "--- END OF FILE ${rel_path} ---"
      echo ""
    done
} > "${OUTPUT_FILE}"

echo "Context file successfully created: ${OUTPUT_FILE} ($(wc -l < "${OUTPUT_FILE}") lines)."