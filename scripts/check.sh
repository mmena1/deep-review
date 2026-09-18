#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
  echo "check: $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing required file: $1"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required executable not found: $1"
}

frontmatter_has() {
  local file="$1"
  local key="$2"
  awk -v key="$key" '
    NR == 1 && $0 != "---" { invalid = 1; exit }
    NR > 1 && !closed && $0 == "---" { closed = 1; next }
    NR > 1 && !closed && index($0, key ":") == 1 { found++ }
    END { if (invalid || !closed || found != 1) exit 1 }
  ' "$file" || fail "$file has invalid frontmatter or is missing $key"
}

frontmatter_parses() {
  local file="$1"
  awk '
    NR == 1 && $0 != "---" { invalid = 1; exit }
    NR > 1 && !closed && $0 == "---" { closed = 1; next }
    NR > 1 && !closed && $0 ~ /^[a-z][a-z-]*:([[:space:]]+.+)?$/ { next }
    NR > 1 && !closed && $0 ~ /^  ([a-z][a-z-]*:([[:space:]]+.+)?|- .+)$/ { next }
    NR > 1 && !closed && $0 ~ /^    - .+$/ { next }
    NR > 1 && !closed && $0 ~ /^[[:space:]]*$/ { next }
    NR > 1 && !closed { invalid = 1 }
    END { if (invalid || !closed) exit 1 }
  ' "$file" || fail "$file is not valid deep-review native frontmatter"
}

yaml_subset_parses() {
  local file="$1"
  awk '
    /^[[:space:]]*$/ || /^#/ { next }
    /^[a-z][a-z_]*:([[:space:]]+.+)?$/ { next }
    /^  [a-z][a-z_]*:([[:space:]]+.+)?$/ { next }
    { invalid = 1 }
    END { if (invalid) exit 1 }
  ' "$file" || fail "$file is not valid deep-review native YAML"
}

toml_string() {
  local file="$1"
  local key="$2"
  local count
  count="$(grep -Ec "^${key} = \"[^\"]+\"$" "$file" || true)"
  [ "$count" -eq 1 ] || fail "$file must define exactly one TOML string for $key"
}

toml_parses() {
  local file="$1"
  awk '
    BEGIN { in_multiline = 0; multiline_count = 0 }
    in_multiline && $0 == "\"\"\"" { in_multiline = 0; next }
    in_multiline { next }
    $0 == "developer_instructions = \"\"\"" {
      in_multiline = 1
      multiline_count++
      next
    }
    /^[[:space:]]*$/ || /^#/ { next }
    /^[a-z_]+ = "[^"]*"$/ { next }
    { invalid = 1 }
    END {
      if (invalid || in_multiline || multiline_count != 1) exit 1
    }
  ' "$file" || fail "$file is not valid deep-review Codex agent TOML"
}

require_command git
require_command gh

for file in \
  skills/deep-review/protocol.md \
  skills/deep-review/GLOSSARY.md \
  skills/deep-review/reviewers/SCOUT.md \
  skills/deep-review/reviewers/validator.md \
  skills/deep-review/reviewers/lenses/bugs.md \
  skills/deep-review/reviewers/lenses/structural.md \
  skills/deep-review/reviewers/lenses/conventions.md \
  skills/deep-review/reviewers/lenses/history.md \
  skills/deep-review/reviewers/lenses/docs.md \
  skills/install-deep-review/installation.md \
  install.ps1 \
  docs/capability-matrix.md \
  docs/runtime-acceptance.md; do
  require_file "$file"
done

for harness in devin codex; do
  for skill_name in deep-review install-deep-review; do
    skill="harnesses/$harness/skills/$skill_name/SKILL.md"
    require_file "$skill"
    frontmatter_parses "$skill"
    frontmatter_has "$skill" name
    frontmatter_has "$skill" description
  done
done

for adapter_root in harnesses/devin/skills/deep-review harnesses/codex/skills/deep-review; do
  while IFS= read -r unexpected; do
    case "$unexpected" in
      "$adapter_root/SKILL.md"|harnesses/codex/skills/deep-review/agents/openai.yaml) ;;
      *) fail "shared semantic copy committed under adapter: $unexpected" ;;
    esac
  done < <(find "$adapter_root" -type f | sort)
done

for adapter_root in harnesses/devin/skills/install-deep-review harnesses/codex/skills/install-deep-review; do
  while IFS= read -r unexpected; do
    case "$unexpected" in
      "$adapter_root/SKILL.md"|harnesses/codex/skills/install-deep-review/agents/openai.yaml) ;;
      *) fail "shared installation copy committed under adapter: $unexpected" ;;
    esac
  done < <(find "$adapter_root" -type f | sort)
  grep -q 'Read `installation.md` completely' "$adapter_root/SKILL.md" || fail "$adapter_root/SKILL.md does not delegate to the canonical installation workflow"
done

for agent in \
  code-reviewer \
  code-reviewer-structural \
  code-reviewer-validator-static \
  code-reviewer-validator-probe; do
  file="harnesses/devin/agents/$agent/AGENT.md"
  require_file "$file"
  frontmatter_parses "$file"
  frontmatter_has "$file" name
  frontmatter_has "$file" description
  frontmatter_has "$file" model
  frontmatter_has "$file" allowed-tools
  grep -q '^<!-- BEGIN GENERATED: shared reviewer body -->$' "$file" || fail "$file lacks generated-section start"
  grep -q '^<!-- END GENERATED: shared reviewer body -->$' "$file" || fail "$file lacks generated-section end"
done

for agent in \
  deep-review-scout \
  deep-review-structural \
  deep-review-validator-static \
  deep-review-validator-probe; do
  file="harnesses/codex/agents/$agent.toml"
  require_file "$file"
  toml_parses "$file"
  toml_string "$file" name
  toml_string "$file" description
  toml_string "$file" model
  toml_string "$file" model_reasoning_effort
  toml_string "$file" sandbox_mode
  [ "$(grep -c '^developer_instructions = """$' "$file" || true)" -eq 1 ] || fail "$file must define one developer_instructions block"
  [ "$(grep -c '^"""$' "$file" || true)" -eq 1 ] || fail "$file has an unterminated or ambiguous developer_instructions block"
done

grep -q '^model: gpt-5-6-luna-medium$' harnesses/devin/agents/code-reviewer/AGENT.md || fail "Devin generic scout model drifted"
grep -q '^model: gpt-5-6-sol-medium$' harnesses/devin/agents/code-reviewer-structural/AGENT.md || fail "Devin structural scout model drifted"
grep -q '^model: gpt-5-6-luna-high$' harnesses/devin/agents/code-reviewer-validator-static/AGENT.md || fail "Devin static validator model drifted"
grep -q '^model: gpt-5-6-luna-high$' harnesses/devin/agents/code-reviewer-validator-probe/AGENT.md || fail "Devin probe validator model drifted"
grep -q '^  - write$' harnesses/devin/agents/code-reviewer-validator-probe/AGENT.md || fail "Devin probe validator lacks write capability"
grep -q '^  - exec$' harnesses/devin/agents/code-reviewer/AGENT.md || fail "Devin generic scout exec capability drifted"
grep -q '^  - exec$' harnesses/devin/agents/code-reviewer-structural/AGENT.md || fail "Devin structural scout exec capability drifted"
grep -q '^  - exec$' harnesses/devin/agents/code-reviewer-validator-static/AGENT.md || fail "Devin static validator exec capability drifted"
grep -q 'no-write/no-probe confinement is instruction-enforced' docs/capability-matrix.md || fail "Devin instruction-enforced confinement is not documented"

grep -q '^model = "gpt-5.6-luna"$' harnesses/codex/agents/deep-review-scout.toml || fail "Codex generic scout model drifted"
grep -q '^model = "gpt-5.6-sol"$' harnesses/codex/agents/deep-review-structural.toml || fail "Codex structural scout model drifted"
grep -q '^sandbox_mode = "read-only"$' harnesses/codex/agents/deep-review-validator-static.toml || fail "Codex static validator must be read-only"
grep -q '^sandbox_mode = "workspace-write"$' harnesses/codex/agents/deep-review-validator-probe.toml || fail "Codex probe validator must be writable"
grep -q '^# Structural Lens$' harnesses/devin/agents/code-reviewer-structural/AGENT.md || fail "Devin structural profile lacks the structural lens"
grep -q '^# Structural Lens$' harnesses/codex/agents/deep-review-structural.toml || fail "Codex structural profile lacks the structural lens"
if grep -q '^# Structural Lens$' harnesses/devin/agents/code-reviewer/AGENT.md harnesses/codex/agents/deep-review-scout.toml; then
  fail "generic scout profile unexpectedly embeds the structural lens"
fi

require_file harnesses/codex/skills/deep-review/agents/openai.yaml
yaml_subset_parses harnesses/codex/skills/deep-review/agents/openai.yaml
grep -q '^policy:$' harnesses/codex/skills/deep-review/agents/openai.yaml || fail "Codex skill metadata lacks policy"
grep -q '^  allow_implicit_invocation: false$' harnesses/codex/skills/deep-review/agents/openai.yaml || fail "Codex skill must remain explicit-only"
require_file harnesses/codex/skills/install-deep-review/agents/openai.yaml
yaml_subset_parses harnesses/codex/skills/install-deep-review/agents/openai.yaml
grep -q '^  allow_implicit_invocation: false$' harnesses/codex/skills/install-deep-review/agents/openai.yaml || fail "Codex install skill must remain explicit-only"
grep -q '^  - user$' harnesses/devin/skills/install-deep-review/SKILL.md || fail "Devin install skill must remain user-triggered"
grep -q '^## Runtime acceptance receipt$' skills/deep-review/protocol.md || fail "shared protocol lacks runtime acceptance receipts"
grep -q 'PASS / FAIL / NOT EXERCISED' skills/deep-review/references/output-template.md || fail "final report lacks the runtime receipt schema"

if grep -R -n -E -i 'Devin|Codex|run_subagent|spawn_agent|gpt-[0-9]|allowed-tools|sandbox_mode|model_reasoning_effort|\.config/devin|\.codex' \
  skills/deep-review; then
  fail "harness-specific metadata leaked into shared protocol/reviewer sources"
fi

for wrapper in harnesses/devin/skills/deep-review/SKILL.md harnesses/codex/skills/deep-review/SKILL.md; do
  grep -q 'Read `protocol.md` completely' "$wrapper" || fail "$wrapper does not delegate semantics to the shared protocol"
  if grep -n -E '^## (Hypotheses|Deduplication|Validation outcomes|Pipeline invariants|Present, decide, and publish)$' "$wrapper"; then
    fail "$wrapper redefines shared protocol semantics"
  fi
done

bash scripts/sync-agents.sh --check

if [ "${DEEP_REVIEW_SKIP_TESTS:-0}" != "1" ]; then
  bash tests/distribution.sh
fi

echo "Deep-review static, adapter, and distribution checks passed."
