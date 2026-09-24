<#
.SYNOPSIS
  Install the llm-wiki integration for GitHub Copilot into a repo.

.DESCRIPTION
  GitHub Copilot has no plugin system; it reads repository custom instructions from
  .github/copilot-instructions.md. This script installs that pointer file (merging into any
  existing one via a managed block) so Copilot is told to read the repo's .llm-wiki/ knowledge
  base first. Optionally it also scaffolds .llm-wiki/ from the bundled templates.

.PARAMETER Target
  Path to the repo to install into (default: current directory).

.PARAMETER Scaffold
  Also copy the template wiki pages into <repo>\.llm-wiki\ if none exists.

.PARAMETER AllPointers
  Also install CLAUDE.md and AGENTS.md pointers (not just Copilot).

.EXAMPLE
  .\scripts\install-copilot.ps1 C:\code\my-repo -Scaffold
#>
param(
  [string]$Target = ".",
  [switch]$Scaffold,
  [switch]$AllPointers
)

$ErrorActionPreference = "Stop"

$PluginRoot = Split-Path -Parent $PSScriptRoot
$Templates  = Join-Path $PluginRoot "templates"

if (-not (Test-Path (Join-Path $Templates "pointers"))) {
  Write-Error "templates not found at $Templates - run this script from within the llm-wiki plugin."
}

$resolved = Resolve-Path -LiteralPath $Target -ErrorAction SilentlyContinue
if (-not $resolved) { Write-Error "target repo '$Target' not found." }
$Target = $resolved.Path

# Install a managed <!-- BEGIN llm-wiki --> ... <!-- END llm-wiki --> block from a template.
function Install-Block([string]$tpl, [string]$dest) {
  $block = (Get-Content -Raw -LiteralPath $tpl).TrimEnd()
  $dir = Split-Path -Parent $dest
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

  if (-not (Test-Path $dest)) {
    Set-Content -LiteralPath $dest -Value $block -Encoding utf8
    Write-Host "  created  $dest"
  } else {
    $content = Get-Content -Raw -LiteralPath $dest
    if ($content -match "<!-- BEGIN llm-wiki -->") {
      $pattern = "(?s)<!-- BEGIN llm-wiki -->.*?<!-- END llm-wiki -->"
      $new = [regex]::Replace($content, $pattern, { param($m) $block })
      Set-Content -LiteralPath $dest -Value $new.TrimEnd() -Encoding utf8
      Write-Host "  updated  $dest (managed block)"
    } else {
      Add-Content -LiteralPath $dest -Value ("`r`n" + $block) -Encoding utf8
      Write-Host "  appended $dest (managed block)"
    }
  }
}

Write-Host "Installing llm-wiki Copilot integration into: $Target"

if (-not (Test-Path (Join-Path $Target ".git"))) {
  Write-Host "  note: target is not a git repository (Copilot reads committed files - remember to commit)."
}

# 1) Optionally scaffold the wiki pages.
if ($Scaffold) {
  $wikiDir = Join-Path $Target ".llm-wiki"
  if (Test-Path $wikiDir) {
    Write-Host "  skip     .llm-wiki\ already exists - left untouched"
  } else {
    Copy-Item -Recurse -Path (Join-Path $Templates "wiki") -Destination $wikiDir
    Write-Host "  created  $wikiDir (placeholder pages - fill them in)"
  }
}

# 2) Install the Copilot pointer (always).
Install-Block (Join-Path $Templates "pointers\copilot-instructions.md") (Join-Path $Target ".github\copilot-instructions.md")

# 2b) Install Copilot prompt files — the /llm-wiki-init|update|lint commands for VS Code Copilot Chat.
$promptsSrc = Join-Path $Templates "copilot-prompts"
if (Test-Path $promptsSrc) {
  $promptsDest = Join-Path $Target ".github\prompts"
  if (-not (Test-Path $promptsDest)) { New-Item -ItemType Directory -Force -Path $promptsDest | Out-Null }
  Copy-Item -Force -Path (Join-Path $promptsSrc "*.prompt.md") -Destination $promptsDest
  Write-Host "  created  $promptsDest\*.prompt.md  (Copilot: /llm-wiki-init, /llm-wiki-update, /llm-wiki-lint)"
}

# 3) Optionally install the other tools' pointers too.
if ($AllPointers) {
  Install-Block (Join-Path $Templates "pointers\CLAUDE.md") (Join-Path $Target "CLAUDE.md")
  Install-Block (Join-Path $Templates "pointers\AGENTS.md") (Join-Path $Target "AGENTS.md")
}

if (-not (Test-Path (Join-Path $Target ".llm-wiki"))) {
  Write-Host ""
  Write-Host "  warning: $Target has no .llm-wiki\ yet, so Copilot is pointed at a wiki that doesn't exist."
  Write-Host "           Re-run with -Scaffold for starter pages, or generate a real one with"
  Write-Host "           /llm-wiki:init in Claude Code, then fill it in."
}

Write-Host ""
Write-Host "Done. Next steps for GitHub Copilot:"
Write-Host "  - Commit .github\copilot-instructions.md (Copilot reads committed repo files)."
Write-Host "  - In VS Code, ensure setting 'github.copilot.chat.codeGeneration.useInstructionFiles' is on"
Write-Host "    (default in current versions). github.com/mobile Copilot picks it up automatically."
Write-Host "  - To POPULATE the wiki, open Copilot Chat in VS Code (Agent mode) and run '/llm-wiki-init'"
Write-Host "    (prompt files may need the 'chat.promptFiles' setting enabled). Later: /llm-wiki-update,"
Write-Host "    /llm-wiki-lint. No VS Code? Paste .github\prompts\llm-wiki-init.prompt.md into any"
Write-Host "    Copilot agent chat."
