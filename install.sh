#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-detected}"
STAMP="$(date +%Y%m%d-%H%M%S)"
MANAGED_MARKER=".deep-review-managed"

usage() {
  cat <<'EOF'
Usage: ./install.sh [--devin | --codex | --all]

With no option, install into every detected supported harness.
EOF
}

case "$MODE" in
  detected|--devin|--codex|--all) ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

is_windows_shell() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

path_is_within_repo() {
  local candidate="$1"
  local resolved
  if command -v realpath >/dev/null 2>&1; then
    resolved="$(realpath -m -- "$candidate")"
  elif [ -e "$candidate" ]; then
    resolved="$(cd "$(dirname "$candidate")" && pwd -P)/$(basename "$candidate")"
  else
    return 1
  fi
  case "$resolved" in
    "$REPO_ROOT"|"$REPO_ROOT"/*) return 0 ;;
    *) return 1 ;;
  esac
}

symlink_points_into_repo() {
  local dst="$1"
  local target
  target="$(readlink "$dst")" || return 1
  case "$target" in
    /*) path_is_within_repo "$target" ;;
    *) path_is_within_repo "$(dirname "$dst")/$target" ;;
  esac
}

junction_points_into_repo() {
  local dst="$1"
  local win_dst win_repo
  is_windows_shell || return 1
  win_dst="$(cygpath -w "$dst")"
  win_repo="$(cygpath -w "$REPO_ROOT")"
  DR_LINK_PATH="$win_dst" DR_REPO_ROOT="$win_repo" powershell.exe -NoProfile -Command '
    $item = Get-Item -LiteralPath $env:DR_LINK_PATH -Force -ErrorAction Stop
    if (-not $item.LinkType -or -not $item.Target) { exit 1 }
    $target = [string]$item.Target
    if (-not [System.IO.Path]::IsPathRooted($target)) {
      $target = Join-Path $item.Parent.FullName $target
    }
    $resolved = [System.IO.Path]::GetFullPath($target)
    $separator = [System.IO.Path]::DirectorySeparatorChar
    $alternate = [System.IO.Path]::AltDirectorySeparatorChar
    $repo = [System.IO.Path]::GetFullPath($env:DR_REPO_ROOT).TrimEnd($separator, $alternate)
    $repoPrefix = $repo + $separator
    if ($resolved.Equals($repo, [System.StringComparison]::OrdinalIgnoreCase) -or
        $resolved.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) { exit 0 }
    exit 1
  ' >/dev/null 2>&1
}

remove_path() {
  local dst="$1"
  if is_windows_shell && [ -d "$dst" ] && junction_points_into_repo "$dst"; then
    cmd.exe //d //c rmdir "$(cygpath -w "$dst")" >/dev/null
  elif [ -d "$dst" ] && [ ! -L "$dst" ]; then
    rm -rf "$dst"
  else
    rm -f "$dst"
  fi
}

backup_path() {
  local dst="$1"
  local backup="${dst}.bak-${STAMP}"
  echo "Backing up existing $dst to $backup"
  mv "$dst" "$backup"
}

is_managed_skill_root() {
  local dst="$1"
  local marker
  [ -f "$dst/$MANAGED_MARKER" ] || return 1
  marker="$(cat "$dst/$MANAGED_MARKER")"
  [ "$marker" = "$REPO_ROOT" ] && return 0
  if is_windows_shell && [ "$marker" = "$(cygpath -w "$REPO_ROOT")" ]; then return 0; fi
  return 1
}

prepare_skill_root() {
  local dst="$1"
  if is_managed_skill_root "$dst"; then
    return
  fi
  if [ -L "$dst" ] && symlink_points_into_repo "$dst"; then
    echo "Replacing repository skill link at $dst"
    remove_path "$dst"
  elif [ -e "$dst" ] && junction_points_into_repo "$dst"; then
    echo "Replacing repository skill junction at $dst"
    remove_path "$dst"
  elif [ -e "$dst" ] || [ -L "$dst" ]; then
    backup_path "$dst"
  fi
  mkdir -p "$dst"
  if is_windows_shell; then
    cygpath -w "$REPO_ROOT" > "$dst/$MANAGED_MARKER"
  else
    printf '%s\n' "$REPO_ROOT" > "$dst/$MANAGED_MARKER"
  fi
}

materialize_path() {
  local src="$1"
  local dst="$2"
  LINK_ACTION="Linked"
  if is_windows_shell; then
    if [ -d "$src" ]; then
      if ! cmd.exe //d //c mklink //J "$(cygpath -w "$dst")" "$(cygpath -w "$src")" >/dev/null 2>&1; then
        cp -R "$src" "$dst"
        LINK_ACTION="Copied"
      fi
    elif ! cmd.exe //d //c mklink //H "$(cygpath -w "$dst")" "$(cygpath -w "$src")" >/dev/null 2>&1; then
      cp "$src" "$dst"
      LINK_ACTION="Copied"
    fi
  else
    ln -s "$src" "$dst"
  fi
}

install_path() {
  local src="$1"
  local dst="$2"
  local managed_parent="${3:-0}"
  if [ -L "$dst" ]; then
    if [ "$managed_parent" -eq 1 ] || symlink_points_into_repo "$dst"; then remove_path "$dst"; else backup_path "$dst"; fi
  elif [ -e "$dst" ]; then
    if [ "$managed_parent" -eq 1 ] || [ "$dst" -ef "$src" ] || junction_points_into_repo "$dst" || { [ -f "$dst" ] && [ -f "$src" ] && cmp -s "$dst" "$src"; }; then
      remove_path "$dst"
    else
      backup_path "$dst"
    fi
  fi
  mkdir -p "$(dirname "$dst")"
  materialize_path "$src" "$dst"
  echo "$LINK_ACTION $dst -> $src"
  if [ "$LINK_ACTION" = "Copied" ]; then
    echo "Warning: link creation failed; rerun the installer after repository updates." >&2
  fi
}

compose_deep_review_skill() {
  local harness="$1" dst="$2"
  local wrapper="$REPO_ROOT/harnesses/$harness/skills/deep-review"
  local shared="$REPO_ROOT/skills/deep-review"
  prepare_skill_root "$dst"
  install_path "$wrapper/SKILL.md" "$dst/SKILL.md" 1
  install_path "$shared/protocol.md" "$dst/protocol.md" 1
  install_path "$shared/GLOSSARY.md" "$dst/GLOSSARY.md" 1
  install_path "$shared/references" "$dst/references" 1
  install_path "$shared/reviewers" "$dst/reviewers" 1
  if [ "$harness" = "codex" ]; then install_path "$wrapper/agents" "$dst/agents" 1; fi
}

compose_install_skill() {
  local harness="$1" dst="$2"
  local wrapper="$REPO_ROOT/harnesses/$harness/skills/install-deep-review"
  local shared="$REPO_ROOT/skills/install-deep-review"
  prepare_skill_root "$dst"
  install_path "$wrapper/SKILL.md" "$dst/SKILL.md" 1
  install_path "$shared/installation.md" "$dst/installation.md" 1
  if [ "$harness" = "codex" ]; then install_path "$wrapper/agents" "$dst/agents" 1; fi
}

install_devin() {
  local root="${HOME}/.config/devin" agent
  compose_deep_review_skill devin "$root/skills/deep-review"
  compose_install_skill devin "$root/skills/install-deep-review"
  for agent in code-reviewer code-reviewer-structural code-reviewer-validator-static code-reviewer-validator-probe; do
    install_path "$REPO_ROOT/harnesses/devin/agents/$agent" "$root/agents/$agent"
  done
  echo "Devin adapters installed. Verify with: devin skills list"
}

install_codex() {
  local agent
  compose_deep_review_skill codex "${HOME}/.agents/skills/deep-review"
  compose_install_skill codex "${HOME}/.agents/skills/install-deep-review"
  for agent in deep-review-scout deep-review-structural deep-review-validator-static deep-review-validator-probe; do
    install_path "$REPO_ROOT/harnesses/codex/agents/$agent.toml" "${HOME}/.codex/agents/$agent.toml"
  done
  echo "Codex adapters installed. Start a fresh Codex session to verify discovery."
}

INSTALL_DEVIN=0
INSTALL_CODEX=0
case "$MODE" in
  --devin) INSTALL_DEVIN=1 ;;
  --codex) INSTALL_CODEX=1 ;;
  --all) INSTALL_DEVIN=1; INSTALL_CODEX=1 ;;
  detected)
    if command -v devin >/dev/null 2>&1 || [ -d "${HOME}/.config/devin" ]; then INSTALL_DEVIN=1; fi
    if command -v codex >/dev/null 2>&1 || [ -d "${HOME}/.codex" ] || [ -d "${HOME}/.agents" ]; then INSTALL_CODEX=1; fi
    if [ "$INSTALL_DEVIN" -eq 0 ] && [ "$INSTALL_CODEX" -eq 0 ]; then
      echo "No supported harness detected. Use --devin, --codex, or --all." >&2
      exit 1
    fi
    ;;
esac
if [ "$INSTALL_DEVIN" -eq 1 ]; then install_devin; fi
if [ "$INSTALL_CODEX" -eq 1 ]; then install_codex; fi
echo "Install complete. Global concurrency settings were not changed."
