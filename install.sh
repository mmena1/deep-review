#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${HOME}/.config/devin"

install_dir() {
  local src="$1"
  local dst="$2"
  local backup_name

  if [ -L "$dst" ]; then
    echo "Removing existing symlink at $dst"
    rm "$dst"
  elif [ -e "$dst" ]; then
    backup_name="${dst}.bak-$(date +%Y%m%d-%H%M%S)"
    echo "Backing up existing $dst to $backup_name"
    mv "$dst" "$backup_name"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "Linked $dst -> $src"
}

install_dir "$REPO_ROOT/skills/deep-review" "$CONFIG_DIR/skills/deep-review"

for agent in code-reviewer code-reviewer-structural; do
  install_dir "$REPO_ROOT/agents/$agent" "$CONFIG_DIR/agents/$agent"
done

echo "Install complete."
echo "Verify with: devin skills list"
