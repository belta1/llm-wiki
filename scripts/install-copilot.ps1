<#
.SYNOPSIS
  Install the llm-wiki integration for GitHub Copilot into a repo.

.DESCRIPTION
  GitHub Copilot has no plugin system; it reads repository custom instructions from
  .github/copilot-instructions.md. This script installs that pointer file (merging into any
  existing one via a managed block) so Copilot is told to read the repo's .llm-wiki/ knowledge
  base first, plus the /llm-wiki-* prompt files (/llm-wiki-init, -update, -lint, -upgrade, -view)
  and the deterministic lint CLI at .llm-wiki\bin\llm-wiki. Optionally it also scaffolds
  .llm-wiki\ from the bundled templates.

  It also installs path-scoped instructions (.github/instructions/<stack>.instructions.md) for
  each stack it detects in the target:
    tsql      *.sqlproj / *.dtsx, or *.sql with T-SQL syntax (GO, SET NOCOUNT, NVARCHAR, ...)
    postgres  *.sql with PostgreSQL syntax ($$, plpgsql, \i, JSONB, ...), .psqlrc, sqitch.plan
    r         *.R / *.Rmd, renv.lock, *.Rproj, _targets.R, an R package DESCRIPTION
    slurm     *.sbatch / *.slurm, or shell scripts containing #SBATCH

  Idempotent: re-running replaces only the managed block / plugin-owned files. Files are read and
  written as UTF-8 without a BOM (Windows PowerShell 5.1 would otherwise misread the templates and
  prepend a BOM to your CLAUDE.md / AGENTS.md).

.PARAMETER Target
  Path to the repo to install into (default: current directory).

.PARAMETER Scaffold
  Also copy the template wiki pages into <repo>\.llm-wiki\ if none exists.

.PARAMETER View
  Also scaffold the HTML view (<repo>\.llm-wiki\view\index.html) and gitignore it. It's a human-only
  review dashboard; regenerate with the /llm-wiki-view prompt. Agents still read the Markdown.

.PARAMETER AllPointers
  Also install CLAUDE.md and AGENTS.md pointers (not just Copilot).

.PARAMETER Tsql
  Install the T-SQL path-scoped instructions even if not detected.

.PARAMETER Postgres
  Install the PostgreSQL path-scoped instructions even if not detected.

.PARAMETER RLang
  Install the R path-scoped instructions even if not detected. Alias: -R.

.PARAMETER Slurm
  Install the Slurm path-scoped instructions even if not detected.

.PARAMETER NoPathInstructions
  Never install path-scoped instructions (.github/instructions/*.instructions.md).

.PARAMETER NoCli
  Don't install the deterministic lint CLI (.llm-wiki\bin\llm-wiki). The /llm-wiki-lint and
  /llm-wiki-upgrade prompts then do every check themselves instead of starting from its output.

.PARAMETER DataSourcesProfileDir
  Write/refresh the cross-project data-source instruction file into this VS Code *user-profile*
  instructions directory. The file (llm-wiki-data-sources.instructions.md) is generated from
  ~/.claude/llm-wiki/data-sources.md so Copilot sees the same named servers/DSNs as Claude. Omit to
  only print how to set it up (the location varies, so the script never guesses it). VS Code-only.

.EXAMPLE
  .\scripts\install-copilot.ps1 C:\code\my-repo -Scaffold

.EXAMPLE
  .\scripts\install-copilot.ps1 C:\code\my-db -AllPointers -Tsql

.EXAMPLE
  .\scripts\install-copilot.ps1 C:\code\sim-study -R -Slurm
#>
param(
  [string]$Target = ".",
  [switch]$Scaffold,
  [switch]$View,
  [switch]$AllPointers,
  [switch]$Tsql,
  [switch]$Postgres,
  [Alias("R")][switch]$RLang,
  [switch]$Slurm,
  [switch]$NoPathInstructions,
  [switch]$NoCli,
  [string]$DataSourcesProfileDir = ""
)

$ErrorActionPreference = "Stop"

$PluginRoot = Split-Path -Parent $PSScriptRoot
$Templates  = Join-Path $PluginRoot "templates"
$Utf8NoBom  = New-Object System.Text.UTF8Encoding $false

if (-not (Test-Path (Join-Path $Templates "pointers"))) {
  Write-Error "templates not found at $Templates - run this script from within the llm-wiki plugin."
}

$resolved = Resolve-Path -LiteralPath $Target -ErrorAction SilentlyContinue
if (-not $resolved) { Write-Error "target repo '$Target' not found." }
$Target = $resolved.Path

function Read-Utf8([string]$path) {
  # ReadAllText strips a BOM if present and decodes as UTF-8 otherwise.
  return [System.IO.File]::ReadAllText($path, $Utf8NoBom)
}

function Write-Utf8([string]$path, [string]$text) {
  [System.IO.File]::WriteAllText($path, $text, $Utf8NoBom)
}

function Ensure-Dir([string]$dir) {
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
}

# Install a managed <!-- BEGIN llm-wiki --> ... <!-- END llm-wiki --> block from a template.
# Creates the file if absent, replaces the block if present, appends it otherwise. Keeps the
# destination's existing line-ending style.
function Install-Block([string]$tpl, [string]$dest) {
  $block = (Read-Utf8 $tpl).TrimEnd() -replace "`r`n", "`n"
  Ensure-Dir (Split-Path -Parent $dest)

  if (-not (Test-Path $dest)) {
    Write-Utf8 $dest ($block + "`n")
    Write-Host "  created  $dest"
    return
  }

  $content = Read-Utf8 $dest
  $nl = if ($content -match "`r`n") { "`r`n" } else { "`n" }
  $block = $block -replace "`n", $nl

  if ($content -match "<!-- BEGIN llm-wiki -->") {
    $pattern = "(?s)<!-- BEGIN llm-wiki -->.*?<!-- END llm-wiki -->"
    $new = [regex]::Replace($content, $pattern, { param($m) $block })
    if ($new -eq $content) {
      Write-Host "  ok       $dest (managed block already current)"
    } else {
      Write-Utf8 $dest $new
      Write-Host "  updated  $dest (managed block)"
    }
  } else {
    Write-Utf8 $dest ($content.TrimEnd() + $nl + $nl + $block + $nl)
    Write-Host "  appended $dest (managed block)"
  }
}

# Ensure the target repo's .gitignore ignores a path (idempotent).
function Add-GitIgnore([string]$line) {
  $gi = Join-Path $Target ".gitignore"
  if (Test-Path $gi) {
    if (@(Get-Content -LiteralPath $gi) -contains $line) {
      Write-Host "  ok       .gitignore already ignores $line"; return
    }
    $existing = Read-Utf8 $gi
    $nl = if ($existing -match "`r`n") { "`r`n" } else { "`n" }
    Write-Utf8 $gi ($existing.TrimEnd() + $nl + $nl +
      "# llm-wiki - derived HTML view (regenerate with /llm-wiki-view)" + $nl + $line + $nl)
  } else {
    Write-Utf8 $gi ("# llm-wiki - derived HTML view (regenerate with /llm-wiki-view)`r`n" + $line + "`r`n")
  }
  Write-Host "  updated  $gi (ignore $line)"
}

# Copy a plugin-owned file, reporting created / updated / unchanged.
function Install-File([string]$src, [string]$dest) {
  Ensure-Dir (Split-Path -Parent $dest)
  if (-not (Test-Path $dest)) {
    Copy-Item -LiteralPath $src -Destination $dest
    Write-Host "  created  $dest"
  } elseif ((Get-FileHash -LiteralPath $src).Hash -eq (Get-FileHash -LiteralPath $dest).Hash) {
    Write-Host "  ok       $dest (unchanged)"
  } else {
    Copy-Item -Force -LiteralPath $src -Destination $dest
    Write-Host "  updated  $dest"
  }
}

# Write/refresh the cross-project data-source instruction file into a VS Code user-profile dir.
# The managed <!-- BEGIN/END llm-wiki --> block is regenerated from ~/.claude/llm-wiki/data-sources.md;
# the frontmatter/guidance outside the block (and any other file in the dir) is preserved. The
# namespaced filename means this never collides with instruction files the user authored themselves.
function Install-DataSources([string]$profileDir) {
  $tpl  = Join-Path $Templates "copilot-instructions\data-sources.instructions.md"
  $dest = Join-Path $profileDir "llm-wiki-data-sources.instructions.md"
  Ensure-Dir $profileDir

  $catalog = Join-Path $HOME ".claude\llm-wiki\data-sources.md"
  if (Test-Path $catalog) {
    # Strip a leading YAML frontmatter block; keep the rest as the catalog body.
    $body = ([regex]::Replace((Read-Utf8 $catalog), "(?s)^﻿?---.*?\r?\n---\r?\n", "")).Trim()
  } else {
    $body = '_No data-source catalog found yet. Run `/llm-wiki:init` in Claude Code, or create `~/.claude/llm-wiki/data-sources.md`._'
  }

  if (Test-Path $dest) { $base = Read-Utf8 $dest; $created = $false }
  else                 { $base = Read-Utf8 $tpl;  $created = $true }

  $nl = if ($base -match "`r`n") { "`r`n" } else { "`n" }
  $bodyNl = ($body -replace "`r`n", "`n") -replace "`n", $nl
  $blockText = "<!-- BEGIN llm-wiki -->$nl$bodyNl$nl<!-- END llm-wiki -->"

  if ($base -match "<!-- BEGIN llm-wiki -->") {
    $new = [regex]::Replace($base, "(?s)<!-- BEGIN llm-wiki -->.*?<!-- END llm-wiki -->", { param($m) $blockText })
  } else {
    $new = $base.TrimEnd() + $nl + $nl + $blockText
  }
  $new = $new.TrimEnd() + $nl

  if ($created) {
    Write-Utf8 $dest $new
    Write-Host "  created  $dest"
  } elseif ($new -eq $base) {
    Write-Host "  ok       $dest (data sources already current)"
  } else {
    Write-Utf8 $dest $new
    Write-Host "  updated  $dest (data sources)"
  }
}

# --- Stack detection (read-only; dependency/build/output dirs are skipped) ---------------------

# All files under the target, listed once and reused by every detector.
$script:SourceFiles = $null
function Get-SourceFiles([string]$root) {
  if ($null -eq $script:SourceFiles) {
    $skip = '[\\/](node_modules|\.git|\.venv|venv|bin|obj|dist|build|renv|\.Rproj\.user|_targets)[\\/]'
    $script:SourceFiles = @(Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName.Substring($root.Length) -notmatch $skip })
  }
  return $script:SourceFiles
}

# Files whose name matches any of the -like patterns (case-insensitive).
function Find-Files([string]$root, [string[]]$patterns) {
  Get-SourceFiles $root | Where-Object { $n = $_.Name; @($patterns | Where-Object { $n -like $_ }).Count -gt 0 }
}

function Test-AnyFile([string]$root, [string[]]$patterns) {
  return [bool](Find-Files $root $patterns | Select-Object -First 1)
}

function Test-AnyFileContains([string]$root, [string[]]$patterns, [string]$regex) {
  $hit = Find-Files $root $patterns |
    Select-String -Pattern $regex -List -ErrorAction SilentlyContinue |
    Select-Object -First 1
  return [bool]$hit
}

# *.sql alone doesn't tell T-SQL from PostgreSQL, so look for dialect markers.
$TsqlRegex     = '^\s*GO\s*$|^:r |^:setvar |SET NOCOUNT|NVARCHAR|CREATE OR ALTER|IDENTITY\([0-9]'
$PostgresRegex = '\$\$|plpgsql|^\\i|^\\set |JSONB|TIMESTAMPTZ|BIGSERIAL|CREATE EXTENSION|ON CONFLICT'

function Test-HasTsql([string]$root) {
  (Test-AnyFile $root @("*.sqlproj", "*.dtproj", "*.dtsx")) -or
  (Test-AnyFileContains $root @("*.sql") $TsqlRegex)
}

function Test-HasPostgres([string]$root) {
  (Test-AnyFile $root @(".psqlrc", "sqitch.plan", "pg_service.conf")) -or
  (Test-AnyFileContains $root @("*.sql") $PostgresRegex)
}

function Test-HasR([string]$root) {
  (Test-AnyFile $root @("*.R", "*.Rmd", "renv.lock", "*.Rproj", "_targets.R")) -or
  (Test-AnyFileContains $root @("DESCRIPTION") '^Package:')
}

function Test-HasSlurm([string]$root) {
  (Test-AnyFile $root @("*.sbatch", "*.slurm")) -or
  (Test-AnyFileContains $root @("*.sh", "*.bash", "*.job") '^#SBATCH')
}

# Install templates\copilot-instructions\<name>.instructions.md if forced or detected.
function Install-PathInstructions([string]$name, [bool]$forced, [scriptblock]$detect, [string]$label) {
  if (-not $forced) {
    if (-not (& $detect $Target)) { return }
    Write-Host "  detected $label"
  }
  Install-File (Join-Path $Templates "copilot-instructions\$name.instructions.md") (Join-Path $Target ".github\instructions\$name.instructions.md")
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

# 1b) Optionally scaffold the human-only HTML view and gitignore it.
if ($View) {
  $viewTpl = Join-Path $Templates "view\index.html"
  if (Test-Path $viewTpl) {
    Install-File $viewTpl (Join-Path $Target ".llm-wiki\view\index.html")
    Add-GitIgnore ".llm-wiki/view/"
  } else {
    Write-Host "  skip     view template not found at $viewTpl"
  }
}

# 2) Install the Copilot pointer (always).
Install-Block (Join-Path $Templates "pointers\copilot-instructions.md") (Join-Path $Target ".github\copilot-instructions.md")

# 2b) Install Copilot prompt files - /llm-wiki-init, -update, -lint, -upgrade and -view in VS Code
# Copilot Chat. Globbed, so a prompt added to the plugin ships without editing this script.
$promptsSrc = Join-Path $Templates "copilot-prompts"
if (Test-Path $promptsSrc) {
  $promptsDest = Join-Path $Target ".github\prompts"
  Get-ChildItem -LiteralPath $promptsSrc -Filter "*.prompt.md" | ForEach-Object {
    Install-File $_.FullName (Join-Path $promptsDest $_.Name)
  }
}

# 2b-ii) Install the deterministic lint CLI next to the wiki it checks. Copilot has no
# ${CLAUDE_PLUGIN_ROOT}, so the script has to live in the target repo for /llm-wiki-lint to run it.
if (-not $NoCli) {
  $cliSrc = Join-Path $PluginRoot "scripts\llm-wiki"
  if (Test-Path $cliSrc) {
    Install-File $cliSrc (Join-Path $Target ".llm-wiki\bin\llm-wiki")
  } else {
    Write-Host "  skip     lint CLI not found at $cliSrc"
  }
}

# 2c) Path-scoped instructions for each detected (or requested) stack.
if (-not $NoPathInstructions) {
  Install-PathInstructions "tsql"     $Tsql.IsPresent     { param($r) Test-HasTsql $r }     "T-SQL sources (*.sqlproj / *.dtsx / T-SQL *.sql)"
  Install-PathInstructions "postgres" $Postgres.IsPresent { param($r) Test-HasPostgres $r } "PostgreSQL sources (psql / PL/pgSQL *.sql)"
  Install-PathInstructions "r"        $RLang.IsPresent    { param($r) Test-HasR $r }        "R sources (*.R / *.Rmd / renv / targets)"
  Install-PathInstructions "slurm"    $Slurm.IsPresent    { param($r) Test-HasSlurm $r }    "Slurm batch scripts (#SBATCH)"
}

# 2d) Optional: cross-project data-source catalog as a VS Code user-profile instruction file.
if ($DataSourcesProfileDir) {
  Write-Host "Installing data-source catalog instruction file (VS Code user profile):"
  Install-DataSources $DataSourcesProfileDir
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
Write-Host "  - Commit .github\ (Copilot reads committed repo files)."
Write-Host "  - In VS Code, ensure setting 'github.copilot.chat.codeGeneration.useInstructionFiles' is on"
Write-Host "    (default in current versions). github.com/mobile Copilot picks it up automatically."
Write-Host "  - To POPULATE the wiki, open Copilot Chat in VS Code (Agent mode) and run '/llm-wiki-init'"
Write-Host "    (prompt files may need the 'chat.promptFiles' setting enabled). Later: /llm-wiki-update,"
Write-Host "    /llm-wiki-lint, /llm-wiki-upgrade. No VS Code? Paste .github\prompts\llm-wiki-init.prompt.md"
Write-Host "    into any Copilot agent chat."
if (-not $NoCli) {
  Write-Host "  - '/llm-wiki-lint' starts from 'python .llm-wiki\bin\llm-wiki lint', which does the"
  Write-Host "    mechanical checks with no model at all. Run it yourself any time, or in CI."
}
Write-Host "  - For a human review dashboard, run '/llm-wiki-view' (or re-run this script with -View) to"
Write-Host "    build .llm-wiki\view\index.html, then open it in VS Code's Simple Browser. It's derived"
Write-Host "    from the Markdown and gitignored; agents keep reading the Markdown."
if (-not $DataSourcesProfileDir) {
  Write-Host ""
  Write-Host "  - Cross-project data sources (VS Code, optional): in the Command Palette run"
  Write-Host "    'Chat: New Instructions File' and choose 'User' to see your profile instructions folder,"
  Write-Host "    then re-run this script with -DataSourcesProfileDir <that folder> to install a"
  Write-Host "    user-global llm-wiki-data-sources.instructions.md generated from your Claude catalog"
  Write-Host "    (~\.claude\llm-wiki\data-sources.md). It applies in every workspace. VS Code only."
}
