#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ORIGINAL_PATH="$PATH"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_link_target() {
  local path="$1"
  local expected="$2"
  if [ -L "$path" ]; then
    [ "$(readlink "$path")" = "$expected" ] || fail "$path points to $(readlink "$path"), expected $expected"
    return
  fi
  if [ -f "$path" ] && [ "$path" -ef "$expected" ]; then
    return
  fi
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      local win_path win_expected
      win_path="$(cygpath -w "$path")"
      win_expected="$(cygpath -w "$expected")"
      DR_LINK_PATH="$win_path" DR_EXPECTED_TARGET="$win_expected" powershell.exe -NoProfile -Command '
        $item = Get-Item -LiteralPath $env:DR_LINK_PATH -Force -ErrorAction Stop
        if (-not $item.Target) { exit 1 }
        $resolved = [System.IO.Path]::GetFullPath([string]$item.Target)
        $expected = [System.IO.Path]::GetFullPath($env:DR_EXPECTED_TARGET)
        if ($resolved -eq $expected) { exit 0 }
        exit 1
      ' >/dev/null 2>&1 || fail "$path is not linked to $expected"
      return
      ;;
  esac
  fail "$path is not linked to $expected"
}

new_home() {
  mktemp -d "${TMPDIR:-/tmp}/deep-review-test.XXXXXX"
}

test_codex_install() {
  local test_home
  test_home="$(new_home)"
  HOME="$test_home" "$REPO_ROOT/install.sh" --codex >/dev/null

  assert_link_target \
    "$test_home/.agents/skills/deep-review" \
    "$REPO_ROOT/harnesses/codex/skills/deep-review"
  for agent in deep-review-scout deep-review-structural deep-review-validator-static deep-review-validator-probe; do
    assert_link_target \
      "$test_home/.codex/agents/$agent.toml" \
      "$REPO_ROOT/harnesses/codex/agents/$agent.toml"
  done
}

test_all_install() {
  local test_home
  test_home="$(new_home)"
  HOME="$test_home" "$REPO_ROOT/install.sh" --all >/dev/null

  assert_link_target \
    "$test_home/.config/devin/skills/deep-review" \
    "$REPO_ROOT/harnesses/devin/skills/deep-review"
  assert_link_target \
    "$test_home/.agents/skills/deep-review" \
    "$REPO_ROOT/harnesses/codex/skills/deep-review"
  for agent in code-reviewer code-reviewer-structural code-reviewer-validator-static code-reviewer-validator-probe; do
    assert_link_target \
      "$test_home/.config/devin/agents/$agent" \
      "$REPO_ROOT/harnesses/devin/agents/$agent"
  done
}

test_bare_install_detects_supported_harnesses() {
  local test_home fake_bin
  test_home="$(new_home)"
  fake_bin="$test_home/bin"
  mkdir -p "$fake_bin"
  printf '#!/usr/bin/env sh\nexit 0\n' > "$fake_bin/codex"
  chmod +x "$fake_bin/codex"

  HOME="$test_home" PATH="$fake_bin:/usr/bin:/bin:/c/Windows/System32" "$REPO_ROOT/install.sh" >/dev/null

  assert_link_target \
    "$test_home/.agents/skills/deep-review" \
    "$REPO_ROOT/harnesses/codex/skills/deep-review"
  [ ! -e "$test_home/.config/devin/skills/deep-review" ] || fail "bare install selected undetected Devin"
}

test_unrelated_destination_is_backed_up() {
  local test_home destination
  test_home="$(new_home)"
  destination="$test_home/.agents/skills/deep-review"
  mkdir -p "$destination"
  printf 'keep me\n' > "$destination/local.txt"

  HOME="$test_home" "$REPO_ROOT/install.sh" --codex >/dev/null

  assert_link_target \
    "$destination" \
    "$REPO_ROOT/harnesses/codex/skills/deep-review"
  local backups=("$destination".bak-*)
  [ "${#backups[@]}" -eq 1 ] || fail "expected one backup for unrelated destination"
  [ "$(cat "${backups[0]}/local.txt")" = "keep me" ] || fail "backup did not preserve destination"
}

test_unrelated_broken_symlink_is_backed_up() {
  local test_home destination
  test_home="$(new_home)"
  destination="$test_home/.agents/skills/deep-review"
  mkdir -p "$(dirname "$destination")"
  ln -s "$test_home/unrelated-missing-target" "$destination" 2>/dev/null || return 0
  [ -L "$destination" ] || return 0

  HOME="$test_home" "$REPO_ROOT/install.sh" --codex >/dev/null

  assert_link_target \
    "$destination" \
    "$REPO_ROOT/harnesses/codex/skills/deep-review"
  local backups=("$destination".bak-*)
  [ "${#backups[@]}" -eq 1 ] || fail "expected one backup for unrelated broken symlink"
  [ "$(readlink "${backups[0]}")" = "$test_home/unrelated-missing-target" ] || fail "broken symlink backup changed its target"
}

test_managed_broken_symlink_is_replaced() {
  local test_home destination
  test_home="$(new_home)"
  destination="$test_home/.config/devin/skills/deep-review"
  mkdir -p "$(dirname "$destination")"
  ln -s "$REPO_ROOT/agents/legacy-deep-review-missing" "$destination" 2>/dev/null || return 0
  [ -L "$destination" ] || return 0

  HOME="$test_home" "$REPO_ROOT/install.sh" --devin >/dev/null

  assert_link_target \
    "$destination" \
    "$REPO_ROOT/harnesses/devin/skills/deep-review"
  local backups=("$destination".bak-*)
  [ ! -e "${backups[0]}" ] || fail "managed broken symlink should not be backed up"
}

test_sync_preserves_installed_agent_link() (
  local test_home source backup installed marker
  test_home="$(new_home)"
  source="$REPO_ROOT/skills/deep-review/reviewers/SCOUT.md"
  backup="$(mktemp "${TMPDIR:-/tmp}/deep-review-scout.XXXXXX")"
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

  assert_link_target \
    "$installed" \
    "$REPO_ROOT/harnesses/codex/agents/deep-review-scout.toml"
  grep -q "$marker" "$installed" || fail "installed Codex agent did not receive synchronized reviewer body"
)

test_windows_file_link_falls_back_to_copy() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *) return 0 ;;
  esac

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
    *"rerun the installer after adapter updates"*) ;;
    *) fail "copy fallback did not warn about update behavior" ;;
  esac
}

test_check_detects_generated_drift() {
  DEEP_REVIEW_SKIP_TESTS=1 "$REPO_ROOT/scripts/check.sh" >/dev/null

  local agent="$REPO_ROOT/harnesses/codex/agents/deep-review-scout.toml"
  local backup
  backup="$(mktemp "${TMPDIR:-/tmp}/deep-review-agent.XXXXXX")"
  cp "$agent" "$backup"
  trap 'cp "$backup" "$agent"; rm -f "$backup"' RETURN
  sed -i '0,/# Scout Contract/s//# Drifted Scout Contract/' "$agent"
  if DEEP_REVIEW_SKIP_TESTS=1 "$REPO_ROOT/scripts/check.sh" >/dev/null 2>&1; then
    fail "check.sh accepted stale generated agent content"
  fi
  cp "$backup" "$agent"
  rm -f "$backup"
  trap - RETURN
}

PATH="$ORIGINAL_PATH"
test_codex_install
test_all_install
test_bare_install_detects_supported_harnesses
test_unrelated_destination_is_backed_up
test_unrelated_broken_symlink_is_backed_up
test_managed_broken_symlink_is_replaced
test_sync_preserves_installed_agent_link
test_windows_file_link_falls_back_to_copy
test_check_detects_generated_drift

echo "Distribution tests passed."
