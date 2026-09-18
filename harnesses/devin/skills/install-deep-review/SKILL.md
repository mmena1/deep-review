---
name: install-deep-review
model: gpt-5-6-sol-medium
triggers:
  - user
description: Install or refresh Deep Review for the requested supported harnesses.
argument-hint: "[--devin | --codex | --all]"
permissions:
  allow:
    - Read(**)
    - Exec(bash install.sh*)
    - Exec(powershell* install.ps1*)
    - Exec(devin skills list)
    - Exec(devin -p*)
---

# Install Deep Review for Devin

Read `installation.md` completely and execute it using Devin's native command and approval mechanisms.
