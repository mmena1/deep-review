[CmdletBinding()]
param(
    [switch]$Devin,
    [switch]$Codex,
    [switch]$All,
    [string]$HomePath = $HOME
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$ManagedMarker = '.deep-review-managed'

function Test-InstalledPath {
    param([string]$Path)
    return $null -ne (Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue)
}

function Test-PathWithinRepo {
    param([string]$Candidate)
    try { $resolved = [System.IO.Path]::GetFullPath($Candidate) } catch { return $false }
    $separators = [char[]]@([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $repo = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd($separators)
    return $resolved.Equals($repo, [System.StringComparison]::OrdinalIgnoreCase) -or
        $resolved.StartsWith($repo + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-LinkIntoRepo {
    param([string]$Path)
    if (-not (Test-InstalledPath $Path)) { return $false }
    $item = Get-Item -LiteralPath $Path -Force
    if (-not $item.LinkType -or -not $item.Target) { return $false }
    foreach ($candidate in @($item.Target)) {
        $target = [string]$candidate
        if (-not $target) { continue }
        if (-not [System.IO.Path]::IsPathRooted($target)) {
            $target = Join-Path $item.Parent.FullName $target
        }
        if (Test-PathWithinRepo $target) { return $true }
    }
    return $false
}

function Remove-InstalledPath {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.LinkType -and $item.PSIsContainer) {
        [System.IO.Directory]::Delete($item.FullName)
    } elseif ($item.LinkType) {
        [System.IO.File]::Delete($item.FullName)
    } elseif ($item.PSIsContainer) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    } else {
        Remove-Item -LiteralPath $Path -Force
    }
}

function Backup-InstalledPath {
    param([string]$Path)
    $backup = "$Path.bak-$Stamp"
    Write-Host "Backing up existing $Path to $backup"
    Move-Item -LiteralPath $Path -Destination $backup
}

function Test-ManagedSkillRoot {
    param([string]$Path)
    $marker = Join-Path $Path $ManagedMarker
    if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { return $false }
    $recorded = (Get-Content -LiteralPath $marker -Raw).Trim()
    if ($recorded -match '^/([A-Za-z])/(.*)$') {
        $recorded = $Matches[1] + ':\' + $Matches[2].Replace('/', '\')
    }
    try {
        $recorded = [System.IO.Path]::GetFullPath($recorded).TrimEnd('\', '/')
        $repo = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\', '/')
        return $recorded.Equals($repo, [System.StringComparison]::OrdinalIgnoreCase)
    } catch {
        return $false
    }
}

function Initialize-SkillRoot {
    param([string]$Path)
    if (Test-ManagedSkillRoot $Path) { return }
    if (Test-InstalledPath $Path) {
        if (Test-LinkIntoRepo $Path) { Remove-InstalledPath $Path } else { Backup-InstalledPath $Path }
    }
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Set-Content -LiteralPath (Join-Path $Path $ManagedMarker) -Value $RepoRoot
}

function New-InstalledPath {
    param([string]$Source, [string]$Destination)
    $script:LinkAction = 'Linked'
    if (Test-Path -LiteralPath $Source -PathType Container) {
        try {
            New-Item -ItemType Junction -Path $Destination -Target $Source -ErrorAction Stop | Out-Null
        } catch {
            Copy-Item -LiteralPath $Source -Destination $Destination -Recurse
            $script:LinkAction = 'Copied'
        }
    } else {
        try {
            New-Item -ItemType HardLink -Path $Destination -Target $Source -ErrorAction Stop | Out-Null
        } catch {
            Copy-Item -LiteralPath $Source -Destination $Destination
            $script:LinkAction = 'Copied'
        }
    }
}

function Test-FilesEqual {
    param([string]$First, [string]$Second)
    if (-not (Test-Path -LiteralPath $First -PathType Leaf) -or -not (Test-Path -LiteralPath $Second -PathType Leaf)) { return $false }
    return (Get-FileHash -LiteralPath $First).Hash -eq (Get-FileHash -LiteralPath $Second).Hash
}

function Install-Path {
    param([string]$Source, [string]$Destination, [switch]$ManagedParent)
    if (Test-InstalledPath $Destination) {
        if ($ManagedParent -or (Test-LinkIntoRepo $Destination) -or (Test-FilesEqual $Destination $Source)) {
            Remove-InstalledPath $Destination
        } else {
            Backup-InstalledPath $Destination
        }
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    New-InstalledPath $Source $Destination
    Write-Host "$script:LinkAction $Destination -> $Source"
    if ($script:LinkAction -eq 'Copied') {
        Write-Warning 'Link creation failed; rerun the installer after repository updates.'
    }
}

function Install-DeepReviewSkill {
    param([string]$Harness, [string]$Destination)
    $wrapper = Join-Path $RepoRoot "harnesses/$Harness/skills/deep-review"
    $shared = Join-Path $RepoRoot 'skills/deep-review'
    Initialize-SkillRoot $Destination
    Install-Path (Join-Path $wrapper 'SKILL.md') (Join-Path $Destination 'SKILL.md') -ManagedParent
    Install-Path (Join-Path $shared 'protocol.md') (Join-Path $Destination 'protocol.md') -ManagedParent
    Install-Path (Join-Path $shared 'GLOSSARY.md') (Join-Path $Destination 'GLOSSARY.md') -ManagedParent
    Install-Path (Join-Path $shared 'references') (Join-Path $Destination 'references') -ManagedParent
    Install-Path (Join-Path $shared 'reviewers') (Join-Path $Destination 'reviewers') -ManagedParent
    if ($Harness -eq 'codex') { Install-Path (Join-Path $wrapper 'agents') (Join-Path $Destination 'agents') -ManagedParent }
}

function Install-InstallerSkill {
    param([string]$Harness, [string]$Destination)
    $wrapper = Join-Path $RepoRoot "harnesses/$Harness/skills/install-deep-review"
    $shared = Join-Path $RepoRoot 'skills/install-deep-review'
    Initialize-SkillRoot $Destination
    Install-Path (Join-Path $wrapper 'SKILL.md') (Join-Path $Destination 'SKILL.md') -ManagedParent
    Install-Path (Join-Path $shared 'installation.md') (Join-Path $Destination 'installation.md') -ManagedParent
    if ($Harness -eq 'codex') { Install-Path (Join-Path $wrapper 'agents') (Join-Path $Destination 'agents') -ManagedParent }
}

function Install-DevinAdapter {
    $root = Join-Path $HomePath '.config/devin'
    Install-DeepReviewSkill 'devin' (Join-Path $root 'skills/deep-review')
    Install-InstallerSkill 'devin' (Join-Path $root 'skills/install-deep-review')
    foreach ($agent in @('code-reviewer', 'code-reviewer-structural', 'code-reviewer-validator-static', 'code-reviewer-validator-probe')) {
        Install-Path (Join-Path $RepoRoot "harnesses/devin/agents/$agent") (Join-Path $root "agents/$agent")
    }
    Write-Host 'Devin adapters installed. Verify with: devin skills list'
}

function Install-CodexAdapter {
    Install-DeepReviewSkill 'codex' (Join-Path $HomePath '.agents/skills/deep-review')
    Install-InstallerSkill 'codex' (Join-Path $HomePath '.agents/skills/install-deep-review')
    foreach ($agent in @('deep-review-scout', 'deep-review-structural', 'deep-review-validator-static', 'deep-review-validator-probe')) {
        Install-Path (Join-Path $RepoRoot "harnesses/codex/agents/$agent.toml") (Join-Path $HomePath ".codex/agents/$agent.toml")
    }
    Write-Host 'Codex adapters installed. Start a fresh Codex session to verify discovery.'
}

$installDevin = $Devin -or $All
$installCodex = $Codex -or $All
if (-not $installDevin -and -not $installCodex) {
    $installDevin = [bool](Get-Command devin -ErrorAction SilentlyContinue) -or (Test-Path -LiteralPath (Join-Path $HomePath '.config/devin'))
    $installCodex = [bool](Get-Command codex -ErrorAction SilentlyContinue) -or
        (Test-Path -LiteralPath (Join-Path $HomePath '.codex')) -or
        (Test-Path -LiteralPath (Join-Path $HomePath '.agents'))
    if (-not $installDevin -and -not $installCodex) { throw 'No supported harness detected. Use -Devin, -Codex, or -All.' }
}
if ($installDevin) { Install-DevinAdapter }
if ($installCodex) { Install-CodexAdapter }
Write-Host 'Install complete. Global concurrency settings were not changed.'
