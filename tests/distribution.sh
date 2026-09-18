#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ORIGINAL_PATH="$PATH"
TEST_ROOT="$(mktemp -d "$REPO_ROOT/.distribution-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

is_windows_shell() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

assert_materialized() {
  local path="$1"
  local expected="$2"
  [ -e "$path" ] || [ -L "$path" ] || fail "missing installed path: $path"

  if [ -L "$path" ]; then
    [ "$(readlink "$path")" = "$expected" ] || fail "$path points to $(readlink "$path"), expected $expected"
    return
  fi
  if [ -f "$path" ]; then
    if [ "$path" -ef "$expected" ] || cmp -s "$path" "$expected"; then return; fi
    fail "$path neither links to nor matches $expected"
  fi
  if is_windows_shell; then
    local win_path win_expected
    win_path="$(cygpath -w "$path")"
    win_expected="$(cygpath -w "$expected")"
    if DR_LINK_PATH="$win_path" DR_EXPECTED_TARGET="$win_expected" powershell.exe -NoProfile -Command '
      $item = Get-Item -LiteralPath $env:DR_LINK_PATH -Force -ErrorAction Stop
      if (-not $item.Target) { exit 1 }
      $resolved = [System.IO.Path]::GetFullPath([string]$item.Target)
      $expected = [System.IO.Path]::GetFullPath($env:DR_EXPECTED_TARGET)
      if ($resolved.Equals($expected, [System.StringComparison]::OrdinalIgnoreCase)) { exit 0 }
      exit 1
    ' >/dev/null 2>&1; then
      return
    fi
  fi
  if [ -d "$path" ] && diff -qr "$path" "$expected" >/dev/null; then return; fi
  fail "$path neither links to nor matches $expected"
}

assert_managed_root() {
  local path="$1"
  local marker
  [ -d "$path" ] || fail "missing managed skill root: $path"
  [ -f "$path/.deep-review-managed" ] || fail "$path lacks its managed marker"
  marker="$(cat "$path/.deep-review-managed")"
  if [ "$marker" = "$REPO_ROOT" ]; then return; fi
  if is_windows_shell && [ "$(cygpath -u "$marker")" = "$REPO_ROOT" ]; then return; fi
  fail "$path has the wrong managed marker"
}

assert_codex_shape() {
  local home="$1"
  local skill="$home/.agents/skills/deep-review"
  assert_managed_root "$skill"
  assert_materialized "$skill/SKILL.md" "$REPO_ROOT/harnesses/codex/skills/deep-review/SKILL.md"
  assert_materialized "$skill/protocol.md" "$REPO_ROOT/skills/deep-review/protocol.md"
  assert_materialized "$skill/GLOSSARY.md" "$REPO_ROOT/skills/deep-review/GLOSSARY.md"
  assert_materialized "$skill/references" "$REPO_ROOT/skills/deep-review/references"
  assert_materialized "$skill/reviewers" "$REPO_ROOT/skills/deep-review/reviewers"
  assert_materialized "$skill/agents" "$REPO_ROOT/harnesses/codex/skills/deep-review/agents"

  local agent
  for agent in deep-review-scout deep-review-structural deep-review-validator-static deep-review-validator-probe; do
    assert_materialized "$home/.codex/agents/$agent.toml" "$REPO_ROOT/harnesses/codex/agents/$agent.toml"
  done
}

assert_devin_shape() {
  local home="$1"
  local skill="$home/.config/devin/skills/deep-review"
  assert_managed_root "$skill"
  assert_materialized "$skill/SKILL.md" "$REPO_ROOT/harnesses/devin/skills/deep-review/SKILL.md"
  assert_materialized "$skill/protocol.md" "$REPO_ROOT/skills/deep-review/protocol.md"
  assert_materialized "$skill/GLOSSARY.md" "$REPO_ROOT/skills/deep-review/GLOSSARY.md"
  assert_materialized "$skill/references" "$REPO_ROOT/skills/deep-review/references"
  assert_materialized "$skill/reviewers" "$REPO_ROOT/skills/deep-review/reviewers"

  local agent
  for agent in code-reviewer code-reviewer-structural code-reviewer-validator-static code-reviewer-validator-probe; do
    assert_materialized "$home/.config/devin/agents/$agent" "$REPO_ROOT/harnesses/devin/agents/$agent"
  done
}

new_home() {
  mktemp -d "$TEST_ROOT/home.XXXXXX"
}

test_codex_install() {
  local test_home
  test_home="$(new_home)"
  HOME="$test_home" "$REPO_ROOT/install.sh" --codex >/dev/null
  assert_codex_shape "$test_home"
}

test_all_install() {
  local test_home
  test_home="$(new_home)"
  HOME="$test_home" "$REPO_ROOT/install.sh" --all >/dev/null
  assert_devin_shape "$test_home"
  assert_codex_shape "$test_home"
}

test_bare_install_detects_supported_harnesses() {
  local test_home fake_bin
  test_home="$(new_home)"
  fake_bin="$test_home/bin"
  mkdir -p "$fake_bin"
  printf '#!/usr/bin/env sh\nexit 0\n' > "$fake_bin/codex"
  chmod +x "$fake_bin/codex"

  HOME="$test_home" PATH="$fake_bin:/usr/bin:/bin:/c/Windows/System32" "$REPO_ROOT/install.sh" >/dev/null

  assert_codex_shape "$test_home"
  [ ! -e "$test_home/.config/devin/skills/deep-review" ] || fail "bare install selected undetected Devin"
}

test_unrelated_destination_is_backed_up() {
  local test_home destination
  test_home="$(new_home)"
  destination="$test_home/.agents/skills/deep-review"
  mkdir -p "$destination"
  printf 'keep me\n' > "$destination/local.txt"

  HOME="$test_home" "$REPO_ROOT/install.sh" --codex >/dev/null

  assert_managed_root "$destination"
  local backups=("$destination".bak-*)
  [ "${#backups[@]}" -eq 1 ] || fail "expected one backup for unrelated destination"
  [ "$(cat "${backups[0]}/local.txt")" = "keep me" ] || fail "backup did not preserve destination"
}

test_unrelated_broken_symlink_is_backed_up() {
  local test_home destination target
  test_home="$(new_home)"
  destination="$test_home/.agents/skills/deep-review"
  target="${TMPDIR:-/tmp}/deep-review-unrelated-missing-$$-$RANDOM"
  mkdir -p "$(dirname "$destination")"
  ln -s "$target" "$destination" 2>/dev/null || return 0
  [ -L "$destination" ] || return 0

  HOME="$test_home" "$REPO_ROOT/install.sh" --codex >/dev/null

  assert_managed_root "$destination"
  local backups=("$destination".bak-*)
  [ "${#backups[@]}" -eq 1 ] || fail "expected one backup for unrelated broken symlink"
  [ "$(readlink "${backups[0]}")" = "$target" ] || fail "broken symlink backup changed its target"
}

test_managed_broken_symlink_is_replaced() {
  local test_home destination
  test_home="$(new_home)"
  destination="$test_home/.config/devin/skills/deep-review"
  mkdir -p "$(dirname "$destination")"
  ln -s "$REPO_ROOT/agents/legacy-deep-review-missing" "$destination" 2>/dev/null || return 0
  [ -L "$destination" ] || return 0

  HOME="$test_home" "$REPO_ROOT/install.sh" --devin >/dev/null

  assert_managed_root "$destination"
  local backups=("$destination".bak-*)
  [ ! -e "${backups[0]}" ] || fail "managed broken symlink should not be backed up"
}

test_sync_preserves_installed_agent_link() (
  local test_home source backup installed marker
  test_home="$(new_home)"
  source="$REPO_ROOT/skills/deep-review/reviewers/SCOUT.md"
  backup="$(mktemp "$TEST_ROOT/deep-review-scout.XXXXXX")"
  installed="$test_home/.codex/agents/deep-review-scout.toml"
  marker="sync-preserves-installed-agent-link"

  cp "$source" "$backup"
  trap '
    cp "$backup" "$source"
    "$REPO_ROOT/scripts/sync-agents.sh" >/dev/null
    rm -f "$backup"
  ' EXIT

  HOME="$test_home" "$REPO_ROOT/install.sh" --codex >/dev/null
  printf '\n<!-- %s -->\n' "$marker" >> "$source"
  "$REPO_ROOT/scripts/sync-agents.sh" >/dev/null

  assert_materialized "$installed" "$REPO_ROOT/harnesses/codex/agents/deep-review-scout.toml"
  grep -q "$marker" "$installed" || fail "installed Codex agent did not receive synchronized reviewer body"
)

test_windows_file_link_falls_back_to_copy() {
  is_windows_shell || return 0

  local test_home fake_bin real_cmd installed source output
  test_home="$(new_home)"
  fake_bin="$test_home/bin"
  real_cmd="$(command -v cmd.exe)"
  installed="$test_home/.codex/agents/deep-review-scout.toml"
  source="$REPO_ROOT/harnesses/codex/agents/deep-review-scout.toml"
  mkdir -p "$fake_bin"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'case " $* " in' \
    '  *" //H "*) exit 1 ;;' \
    'esac' \
    'exec "$DR_REAL_CMD" "$@"' > "$fake_bin/cmd.exe"
  chmod +x "$fake_bin/cmd.exe"

  output="$(HOME="$test_home" PATH="$fake_bin:$PATH" DR_REAL_CMD="$real_cmd" "$REPO_ROOT/install.sh" --codex 2>&1)"

  [ -f "$installed" ] || fail "Codex agent copy fallback was not created"
  [ ! "$installed" -ef "$source" ] || fail "copy fallback unexpectedly remained a hardlink"
  cmp -s "$installed" "$source" || fail "Codex agent copy fallback changed file contents"
  case "$output" in
    *"rerun the installer after repository updates"*) ;;
    *) fail "copy fallback did not warn about update behavior" ;;
  esac
}

test_native_powershell_install() {
  is_windows_shell || return 0

  local test_home win_home win_installer
  test_home="$(new_home)"
  win_home="$(cygpath -w "$test_home")"
  win_installer="$(cygpath -w "$REPO_ROOT/install.ps1")"
  HOME="$test_home" "$REPO_ROOT/install.sh" --codex >/dev/null
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$win_installer" -Codex -HomePath "$win_home" >/dev/null
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$win_installer" -Codex -HomePath "$win_home" >/dev/null
  assert_codex_shape "$test_home"
  local backups=("$test_home/.agents/skills/deep-review".bak-*)
  [ ! -e "${backups[0]}" ] || fail "switching installers backed up a managed skill root"
}

test_check_detects_generated_drift() (
  DEEP_REVIEW_SKIP_TESTS=1 "$REPO_ROOT/scripts/check.sh" >/dev/null

  local agent="$REPO_ROOT/harnesses/codex/agents/deep-review-scout.toml"
  local backup
  backup="$(mktemp "$TEST_ROOT/deep-review-agent.XXXXXX")"
  cp "$agent" "$backup"
  trap 'cp "$backup" "$agent"; rm -f "$backup"' EXIT
  awk '
    !changed && $0 == "# Scout Contract" { print "# Drifted Scout Contract"; changed = 1; next }
    { print }
    END { if (!changed) exit 1 }
  ' "$agent" > "$TEST_ROOT/drifted-agent.toml"
  cp "$TEST_ROOT/drifted-agent.toml" "$agent"
  if DEEP_REVIEW_SKIP_TESTS=1 "$REPO_ROOT/scripts/check.sh" >/dev/null 2>&1; then
    fail "check.sh accepted stale generated agent content"
  fi
)

PATH="$ORIGINAL_PATH"
test_codex_install
test_all_install
test_bare_install_detects_supported_harnesses
test_unrelated_destination_is_backed_up
test_unrelated_broken_symlink_is_backed_up
test_managed_broken_symlink_is_replaced
test_sync_preserves_installed_agent_link
test_windows_file_link_falls_back_to_copy
test_native_powershell_install
test_check_detects_generated_drift

echo "Distribution tests passed."
