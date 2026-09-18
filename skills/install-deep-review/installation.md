# Install Deep Review

Install the repository's `deep-review` and `install-deep-review` skills plus the selected harness's native reviewer agents.

1. Read the `.deep-review-managed` marker beside the installed skill to resolve the repository root. When running directly from a checkout, resolve the checkout root containing `skills/install-deep-review/installation.md`, `install.sh`, and `install.ps1`. Stop if the recorded checkout or installers are unavailable.
2. Detect the current operating system and shell, then detect supported harnesses from their commands or existing user configuration directories. Honor an explicit harness argument; otherwise select every detected harness. Stop when none is detected.
3. Before mutation, report the selected harnesses, installer, and personal installation roots. State that unrelated existing destinations are backed up and global concurrency settings remain unchanged.
4. Use the native installer with the narrowest mode:
   - Native Windows PowerShell: `install.ps1` with `-Devin`, `-Codex`, or `-All`.
   - Unix, macOS, WSL, or Git Bash: `install.sh` with `--devin`, `--codex`, or `--all`.
   - Omit the mode only when installing every harness detected by that installer.
5. Preserve installer output. If a destination was copied because linking was unavailable, report that the installer must be rerun after repository updates.
6. Verify the installed shape points to or matches the repository sources. For Devin, run `devin skills list` and `devin -p "List the available subagent profiles"` when the command is available. For Codex, verify both installed skill directories and all four custom-agent files, then require a fresh Codex session for runtime discovery. Report any discovery check that could not be executed.

Completion requires the requested harness installations to be structurally valid, every available native discovery check to pass, and every unavailable runtime check to be named explicitly.
