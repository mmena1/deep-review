#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-detected}"
STAMP="$(date +%Y%m%d-%H%M%S)"

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

symlink_points_into_repo() {
  local dst="$1"
  local target candidate resolved
  target="$(readlink "$dst")" || return 1
  case "$target" in
    /*) candidate="$target" ;;
    *) candidate="$(dirname "$dst")/$target" ;;
  esac

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

remove_managed_link() {
  local dst="$1"
  if is_windows_shell && [ -d "$dst" ] && junction_points_into_repo "$dst"; then
    cmd.exe //d //c rmdir "$(cygpath -w "$dst")" >/dev/null
  else
    rm -f "$dst"
  fi
}

create_link() {
  local src="$1"
  local dst="$2"
  LINK_ACTION="Linked"
  if is_windows_shell; then
    if [ -d "$src" ]; then
      cmd.exe //d //c mklink //J "$(cygpath -w "$dst")" "$(cygpath -w "$src")" >/dev/null
    else
      if ! cmd.exe //d //c mklink //H "$(cygpath -w "$dst")" "$(cygpath -w "$src")" >/dev/null 2>&1; then
        cp "$src" "$dst"
        LINK_ACTION="Copied"
      fi
    fi
  else
    ln -s "$src" "$dst"
  fi
}

install_path() {
  local src="$1"
  local dst="$2"
  local backup

  if [ -L "$dst" ]; then
    if symlink_points_into_repo "$dst"; then
      echo "Replacing repository symlink at $dst"
      remove_managed_link "$dst"
    else
      backup="${dst}.bak-${STAMP}"
      echo "Backing up unrelated symlink $dst to $backup"
      mv "$dst" "$backup"
    fi
  elif [ -e "$dst" ]; then
    if [ "$dst" -ef "$src" ] || junction_points_into_repo "$dst"; then
      echo "Replacing repository link at $dst"
      remove_managed_link "$dst"
    else
      backup="${dst}.bak-${STAMP}"
      echo "Backing up existing $dst to $backup"
      mv "$dst" "$backup"
    fi
  fi

  mkdir -p "$(dirname "$dst")"
  create_link "$src" "$dst"
  echo "$LINK_ACTION $dst -> $src"
  if [ "$LINK_ACTION" = "Copied" ]; then
    echo "Warning: Windows hardlink creation failed; rerun the installer after adapter updates." >&2
  fi
}

install_devin() {
  local root="${HOME}/.config/devin"
  local agent
  install_path "$REPO_ROOT/harnesses/devin/skills/deep-review" "$root/skills/deep-review"
  for agent in code-reviewer code-reviewer-structural code-reviewer-validator-static code-reviewer-validator-probe; do
    install_path "$REPO_ROOT/harnesses/devin/agents/$agent" "$root/agents/$agent"
  done
  echo "Devin adapter installed. Verify with: devin skills list"
}

install_codex() {
  local agent
  install_path "$REPO_ROOT/harnesses/codex/skills/deep-review" "${HOME}/.agents/skills/deep-review"
  for agent in deep-review-scout deep-review-structural deep-review-validator-static deep-review-validator-probe; do
    install_path "$REPO_ROOT/harnesses/codex/agents/$agent.toml" "${HOME}/.codex/agents/$agent.toml"
  done
  echo "Codex adapter installed. Restart Codex if the skill or custom agents do not appear."
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
