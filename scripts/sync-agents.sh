#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-write}"

if [ "$MODE" != "write" ] && [ "$MODE" != "--check" ]; then
  echo "Usage: ./scripts/sync-agents.sh [--check]" >&2
  exit 2
fi

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/deep-review-sync.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT
STALE=0

sync_file() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"
  if [ -f "$target" ] && cmp -s "$source" "$target"; then
    return
  fi

  if [ "$MODE" = "--check" ]; then
    echo "Stale composed adapter file: ${target#"$REPO_ROOT/"}" >&2
    STALE=1
  else
    cp "$source" "$target"
    echo "Synchronized ${target#"$REPO_ROOT/"}"
  fi
}

sync_tree() {
  local source_root="$1"
  local target_root="$2"
  local relative source target extra relative_extra

  while IFS= read -r source; do
    relative="${source#"$source_root/"}"
    target="$target_root/$relative"
    sync_file "$source" "$target"
  done < <(find "$source_root" -type f | sort)

  if [ -d "$target_root" ]; then
    while IFS= read -r extra; do
      relative_extra="${extra#"$target_root/"}"
      if [ ! -f "$source_root/$relative_extra" ]; then
        if [ "$MODE" = "--check" ]; then
          echo "Unexpected composed adapter file: ${extra#"$REPO_ROOT/"}" >&2
          STALE=1
        else
          rm -f "$extra"
          echo "Removed stale ${extra#"$REPO_ROOT/"}"
        fi
      fi
    done < <(find "$target_root" -type f | sort)
  fi
}

replace_section() {
  local target="$1"
  local start="$2"
  local end="$3"
  local body="$4"
  local expected="$TMP_ROOT/$(echo "$target" | tr '/\\' '__')"

  awk -v start="$start" -v end="$end" -v body="$body" '
    $0 == start {
      start_count++
      if (start_count != 1) exit 42
      print
      while ((getline line < body) > 0) print line
      close(body)
      replacing = 1
      found_start = 1
      next
    }
    replacing && $0 == end {
      end_count++
      if (end_count != 1) exit 42
      print
      replacing = 0
      found_end = 1
      next
    }
    !replacing { print }
    END {
      if (!found_start || !found_end || replacing || start_count != 1 || end_count != 1) exit 42
    }
  ' "$REPO_ROOT/$target" > "$expected" || {
    echo "Invalid generated-section markers in $target" >&2
    exit 1
  }

  if cmp -s "$REPO_ROOT/$target" "$expected"; then
    return
  fi

  if [ "$MODE" = "--check" ]; then
    echo "Stale generated reviewer body: $target" >&2
    STALE=1
  else
    cp "$expected" "$REPO_ROOT/$target"
    echo "Synchronized $target"
  fi
}

SCOUT_BODY="$REPO_ROOT/skills/deep-review/reviewers/SCOUT.md"
VALIDATOR_BODY="$REPO_ROOT/skills/deep-review/reviewers/validator.md"
STRUCTURAL_BODY="$TMP_ROOT/structural.md"
CODEX_SCOUT_BODY="$TMP_ROOT/codex-scout.toml"
CODEX_STRUCTURAL_BODY="$TMP_ROOT/codex-structural.toml"
CODEX_VALIDATOR_BODY="$TMP_ROOT/codex-validator.toml"

for adapter in devin codex; do
  ADAPTER_ROOT="$REPO_ROOT/harnesses/$adapter/skills/deep-review"
  sync_file "$REPO_ROOT/skills/deep-review/protocol.md" "$ADAPTER_ROOT/protocol.md"
  sync_file "$REPO_ROOT/skills/deep-review/GLOSSARY.md" "$ADAPTER_ROOT/GLOSSARY.md"
  sync_tree "$REPO_ROOT/skills/deep-review/references" "$ADAPTER_ROOT/references"
  sync_tree "$REPO_ROOT/skills/deep-review/reviewers" "$ADAPTER_ROOT/reviewers"
done

{
  cat "$SCOUT_BODY"
  printf '\n'
  cat "$REPO_ROOT/skills/deep-review/reviewers/lenses/structural.md"
} > "$STRUCTURAL_BODY"

{
  printf 'developer_instructions = """\n'
  cat "$SCOUT_BODY"
  printf '\n"""\n'
} > "$CODEX_SCOUT_BODY"

{
  printf 'developer_instructions = """\n'
  cat "$STRUCTURAL_BODY"
  printf '\n"""\n'
} > "$CODEX_STRUCTURAL_BODY"

{
  printf 'developer_instructions = """\n'
  cat "$VALIDATOR_BODY"
  printf '\n"""\n'
} > "$CODEX_VALIDATOR_BODY"

DEVIN_START='<!-- BEGIN GENERATED: shared reviewer body -->'
DEVIN_END='<!-- END GENERATED: shared reviewer body -->'
CODEX_START='# BEGIN GENERATED: shared reviewer body'
CODEX_END='# END GENERATED: shared reviewer body'

replace_section "harnesses/devin/agents/code-reviewer/AGENT.md" "$DEVIN_START" "$DEVIN_END" "$SCOUT_BODY"
replace_section "harnesses/devin/agents/code-reviewer-structural/AGENT.md" "$DEVIN_START" "$DEVIN_END" "$STRUCTURAL_BODY"
replace_section "harnesses/devin/agents/code-reviewer-validator-static/AGENT.md" "$DEVIN_START" "$DEVIN_END" "$VALIDATOR_BODY"
replace_section "harnesses/devin/agents/code-reviewer-validator-probe/AGENT.md" "$DEVIN_START" "$DEVIN_END" "$VALIDATOR_BODY"

replace_section "harnesses/codex/agents/deep-review-scout.toml" "$CODEX_START" "$CODEX_END" "$CODEX_SCOUT_BODY"
replace_section "harnesses/codex/agents/deep-review-structural.toml" "$CODEX_START" "$CODEX_END" "$CODEX_STRUCTURAL_BODY"
replace_section "harnesses/codex/agents/deep-review-validator-static.toml" "$CODEX_START" "$CODEX_END" "$CODEX_VALIDATOR_BODY"
replace_section "harnesses/codex/agents/deep-review-validator-probe.toml" "$CODEX_START" "$CODEX_END" "$CODEX_VALIDATOR_BODY"

if [ "$STALE" -ne 0 ]; then
  exit 1
fi

if [ "$MODE" = "--check" ]; then
  echo "Generated reviewer bodies are current."
fi
