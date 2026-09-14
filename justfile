# Justfile - Command Automation for desktop_workspace

default: check test

# Install project dependencies
deps:
    flutter pub get

# Upgrade dependencies to latest compatible versions
upgrade:
    flutter pub upgrade

# Run code generation with build_runner (Riverpod generator)
gen:
    dart run build_runner build --delete-conflicting-outputs

# Run code generation in continuous watch mode
gen-watch:
    dart run build_runner watch --delete-conflicting-outputs

# Run strict static code analysis
check:
    flutter analyze

# Auto-format all Dart code in place
fmt:
    dart format .

# Verify formatting without modifying files
fmt-check:
    dart format --output=none --set-exit-if-changed .

# Run test suite
test:
    flutter test

# Run test suite with lcov coverage report generation
coverage:
    flutter test --coverage

# Launch the desktop demo example application
run-example:
    flutter run -t example/main.dart

# Generate Git uncommitted changes report (status, diffs, untracked files)
diff:
    bash scripts/diff_changes.sh

# Collect repository source code, prompts, structure, and environment into context.txt
ctx:
    bash scripts/dump_context.sh

# Run comprehensive verification pipeline (format check, analysis, tests)
verify: fmt-check check test

# Clean build artifacts, coverage data, tool caches, and generated context dumps
clean:
    flutter clean
    rm -rf .dart_tool coverage context.txt changes.txt